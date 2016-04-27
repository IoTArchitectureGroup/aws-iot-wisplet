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
    func setConnectionStatusString(msg: NSString)
    {
        mqttStatus = msg as String
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        appDelegate.setMqttConnectionStatus(msg as String)
    }
    
    func connect() {
        
        func mqttEventCallback( status: AWSIoTMQTTStatus )
        {
            dispatch_async( dispatch_get_main_queue()) {
                print("connection status = \(status.rawValue)")
                switch(status)
                {
                case .Connecting:
                    self.setConnectionStatusString("Connecting...")
                    print( self.mqttStatus )
                    
                case .Connected:
                    self.setConnectionStatusString("Connected")
                    print( self.mqttStatus )
                    let uuid = NSUUID().UUIDString;
                    
                    // Get SCAppDelegate, store UUID there
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    appDelegate.setAppUUID(uuid)
                    print(uuid)
                    
                case .Disconnected:
                    self.setConnectionStatusString("Disconnected")
                    print( self.mqttStatus )
                    
                case .ConnectionRefused:
                    self.setConnectionStatusString("Connection Refused")
                    print( self.mqttStatus )
                    
                case .ConnectionError:
                    self.setConnectionStatusString("Connection Error")
                    print( self.mqttStatus )
                    
                case .ProtocolError:
                    self.setConnectionStatusString("Protocol Error")
                    print( self.mqttStatus )
                    
                default:
                    self.setConnectionStatusString("Unknown State")
                    print("unknown state: \(status.rawValue)")
                    
                }
                NSNotificationCenter.defaultCenter().postNotificationName( "connectionStatusChanged", object: self )
            }
            
        }
        
        if (connected == false)
        {
            let defaults = NSUserDefaults.standardUserDefaults()
            var certificateId = defaults.stringForKey( "certificateId")
            
            if (certificateId == nil)
            {
                print ("No certificate available, creating one...")
                //
                // Now create and store the certificate ID in NSUserDefaults
                //
                let csrDictionary = [ "commonName":CertificateSigningRequestCommonName, "countryName":CertificateSigningRequestCountryName, "organizationName":CertificateSigningRequestOrganizationName, "organizationalUnitName":CertificateSigningRequestOrganizationalUnitName ]
                
                self.iotManager.createKeysAndCertificateFromCsr(csrDictionary, callback: {  (response ) -> Void in
                    if (response != nil)
                    {
                        defaults.setObject(response.certificateId, forKey:"certificateId")
                        defaults.setObject(response.certificateArn, forKey:"certificateArn")
                        certificateId = response.certificateId
                        print("response: [\(response)]")
                        let uuid = NSUUID().UUIDString;
                        
                        let attachPrincipalPolicyRequest = AWSIoTAttachPrincipalPolicyRequest()
                        attachPrincipalPolicyRequest.policyName = PolicyName
                        attachPrincipalPolicyRequest.principal = response.certificateArn
                        //
                        // Attach the policy to the certificate
                        //
                        self.iot.attachPrincipalPolicy(attachPrincipalPolicyRequest).continueWithBlock { (task) -> AnyObject? in
                            if let error = task.error {
                                print("failed: [\(error)]")
                            }
                            if let exception = task.exception {
                                print("failed: [\(exception)]")
                            }
                            print("result: [\(task.result)]")
                            //
                            // Connect to the AWS IoT platform
                            //
                            if (task.exception == nil && task.error == nil)
                            {
                                let delayTime = dispatch_time( DISPATCH_TIME_NOW, Int64(2*Double(NSEC_PER_SEC)))
                                dispatch_after( delayTime, dispatch_get_main_queue()) {
                                    //self.logTextView.text = "Using certificate: \(certificateId!)"
                                    self.iotDataManager.connectWithClientId( uuid, cleanSession:true, certificateId:certificateId, statusCallback: mqttEventCallback)
                                }
                            }
                            return nil
                        }
                    }
                    else
                    {
                        print("Unable to create keys and/or certificate, check values in Constants.swift")
                    }
                } )
            }
            else
            {
                let uuid = NSUUID().UUIDString;
                
                //
                // Connect to the AWS IoT service
                //
                iotDataManager.connectWithClientId( uuid, cleanSession:true, certificateId:certificateId, statusCallback: mqttEventCallback)
            }
        }
    }
    
    func disconnectFromMqttBroker()
    {
        print("Disconnecting...");
        
        dispatch_async( dispatch_get_global_queue(Int(QOS_CLASS_USER_INITIATED.rawValue), 0) ){
            if (self.iotDataManager == nil)
            {
                self.iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
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
        
        AWSServiceManager.defaultServiceManager().defaultServiceConfiguration = configuration
        
        iotManager = AWSIoTManager.defaultIoTManager()
        iot = AWSIoT.defaultIoT()
        
        iotDataManager = AWSIoTDataManager.defaultIoTDataManager()
        iotData = AWSIoTData.defaultIoTData()
        
        connect()
    }
    
    
}

