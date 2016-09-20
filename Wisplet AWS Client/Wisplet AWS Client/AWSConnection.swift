/*
 * Copyright 2010-2015 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 *  http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

import Foundation

class AWSConnection: NSObject {
    
    var connected = false;
    
    var iotDataManager: AWSIoTDataManager!;
    var iotData: AWSIoTData!
    var iotManager: AWSIoTManager!;
    var iot: AWSIoT!
    var mqttStatus = ""
    
    // Quick hack to push this to AppDelegate which pushes to a display delegate 
    // (SensorBoardViewController) which THEN shows it in a text label.
    func setConnectionStatusString(_ msg: NSString)
    {
        mqttStatus = msg as String
        
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.setMqttConnectionStatus(msg as String)
    }
    
    func connect() {
        
        func mqttEventCallback( _ status: AWSIoTMQTTStatus )
        {
            DispatchQueue.main.async {
                print("AWSConnection.swift connection status = \(status.rawValue)")
                switch(status)
                {
                case .connecting:
                    self.setConnectionStatusString("Connecting...")
                    print( self.mqttStatus )
                    
                case .connected:
                    self.setConnectionStatusString("Connected")
                    print( self.mqttStatus )
                    let uuid = UUID().uuidString;
                    
                    // Get SCAppDelegate, store UUID there
                    let appDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDelegate.setAppUUID(uuid)
                    print(uuid)
                    
                case .disconnected:
                    self.setConnectionStatusString("Disconnected")
                    print( self.mqttStatus )
                    
                case .connectionRefused:
                    self.setConnectionStatusString("Connection Refused")
                    print( self.mqttStatus )
                    
                case .connectionError:
                    self.setConnectionStatusString("Connection Error")
                    print( self.mqttStatus )
                    
                case .protocolError:
                    self.setConnectionStatusString("Protocol Error")
                    print( self.mqttStatus )
                    
                default:
                    self.setConnectionStatusString("Unknown State")
                    print("AWSConnection.swift unknown state: \(status.rawValue)")
                    
                }
                NotificationCenter.default.post( name: Notification.Name(rawValue: "connectionStatusChanged"), object: self )
            }
            
        }
        
        if (connected == false)
        {
            let defaults = UserDefaults.standard
            var certificateId = defaults.string( forKey: "certificateId")
            
            if (certificateId == nil)
            {
                print ("AWSConnection.swift: No certificate available, creating one...")
                //
                // Now create and store the certificate ID in NSUserDefaults
                //
                let csrDictionary = [ "commonName":CertificateSigningRequestCommonName, "countryName":CertificateSigningRequestCountryName, "organizationName":CertificateSigningRequestOrganizationName, "organizationalUnitName":CertificateSigningRequestOrganizationalUnitName ]
                
                self.iotManager.createKeysAndCertificate(fromCsr: csrDictionary, callback: {  (response ) -> Void in
                    if (response != nil)
                    {
                        defaults.set(response?.certificateId, forKey:"certificateId")
                        defaults.set(response?.certificateArn, forKey:"certificateArn")
                        certificateId = response?.certificateId
                        print("AWSConnection.swift response: [\(response)]")
                        let uuid = UUID().uuidString;
                        
                        let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
                        attachPrincipalPolicyRequest?.policyName = PolicyName
                        attachPrincipalPolicyRequest?.principal = response?.certificateArn
                        //
                        // Attach the policy to the certificate
                        //
                        self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest!).continue( { (task) -> AnyObject? in
                            if let error = task.error {
                                print("AWSConnection.swift failed: [\(error)]")
                            }
                            if let exception = task.exception {
                                print("AWSConnection.swift failed: [\(exception)]")
                            }
                            print("AWSConnection.swift result: [\(task.result)]")
                            //
                            // Connect to the AWS IoT platform
                            //
                            if (task.exception == nil && task.error == nil)
                            {
                                let delayTime = DispatchTime.now() + Double(Int64(2*Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
                                DispatchQueue.main.asyncAfter( deadline: delayTime) {
                                    //self.logTextView.text = "Using certificate: \(certificateId!)"
                                    self.iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:certificateId, statusCallback: mqttEventCallback)
                                }
                            }
                            return nil
                        } )
                    }
                    else
                    {
                        print("AWSConnection.swift: Unable to create keys and/or certificate, check values in Constants.swift")
                    }
                } )
            }
            else
            {
                let uuid = UUID().uuidString;
                
                //
                // Connect to the AWS IoT service
                //
                iotDataManager.connect( withClientId: uuid, cleanSession:true, certificateId:certificateId, statusCallback: mqttEventCallback)
            }
        }
    }
    
    func disconnectFromMqttBroker()
    {
        print("AWSConnection.swift Disconnecting...");
        
        //DispatchQueue.global(priority: Int(DispatchQoS.QoSClass.userInitiated.rawValue)).async{
        DispatchQueue.global(qos: DispatchQoS.QoSClass.userInitiated).async{
            if (self.iotDataManager == nil)
            {
                self.iotDataManager = AWSIoTDataManager.default()
            }
            self.iotDataManager.disconnect();
            self.connected = false
        }
        
    }
    
    func setupAWSIoT() {
        
        // Init IOT
        //
        // Set up Cognito
        //
        let credentialsProvider = AWSCognitoCredentialsProvider(regionType: AwsRegion, identityPoolId: CognitoIdentityPoolId)
        let configuration = AWSServiceConfiguration(region: AwsRegion, credentialsProvider: credentialsProvider)
        
        AWSServiceManager.default().defaultServiceConfiguration = configuration
        
        iotManager = AWSIoTManager.default()
        iot = AWSIoT.default()
        
        iotDataManager = AWSIoTDataManager.default()
        iotData = AWSIoTData.default()
        
        connect()
    }
    
    
}

