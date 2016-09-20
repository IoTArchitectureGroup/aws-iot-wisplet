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

//WARNING: To run this sample correctly, you must set the following constants.

// Values for AWS account instance
let AwsRegion = AWSRegionType.usEast1 // REQUIRED. e.g. AWSRegionType.usEast1
let CognitoIdentityPoolId = "us-east-1:e2ed4297-61bb-5b17-af96-f7c31d8799f7" // REQUIRED
let CertificateSigningRequestCommonName = "IoTSampleSwift Application"
let CertificateSigningRequestCountryName = "Your Country"
let CertificateSigningRequestOrganizationName = "Your Organization"
let CertificateSigningRequestOrganizationalUnitName = "Your Organizational Unit"
let PolicyName = "PubSubToAnyTopic" // REQUIRED.
