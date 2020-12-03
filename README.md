# ⚡️ AWS Lambda: CSV to DynamoDB Uploader

This tutorial will show you how to deploy a lambda function in AWS which gets triggered on a CSV upload to S3 bucket and insert the records from CSV into DynamoDB using Terraform. Our template will also deploy one REST API endpoint which can be used to query the data uploaded to DynamoDB.

## 👨‍💻 Preparation

To follow this tutorial you will need:
-   An AWS account
-   AWS CLI installed and configured
-   Terraform CLI installed

First of all, download the source code
```
$ git clone https://github.com/srs2210/aws-lambda-csv-2-dynamodb.git

$ cd aws-lambda-csv-2-dynamodb
```
For sake of simplicity you can use credentials with administrative access to your AWS account. Once you have the credentials, you will need to create the environment variables as shown below:
```
$ export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
$ export AWS_SECRET_ACCESS_KEY="YOUR_SECRETY_ACCESS_KEY"
$ export AWS_DEFAULT_REGION="us-east-1"
```

<br/>
> **💡 Pro Tip** : If you have AWS CLI configured locally, Terraform can use that configuration too for authentication with AWS. 
<br/>

Terraform will use the above environment variables to authenticate with AWS for deploying resources. We are using the **us-east-1** region throughout the tutorial. If you want to work with a different region, make the below changes in the downloaded source code.

```
# In terraform.tfvars file add the region of your choice
region = "<YOUR_REGION>"

# In .py files inside the 'zip_files' folder, update the region variable
region = '<YOUR_REGION>'
```
We will be using remote backend for our configuration. If you open the ```backend.tf``` file, you will find the below configuration block:
```
terraform {
 required_providers {
   aws = {
    source  =  "hashicorp/aws"
    version =  "~> 3.0"
   }
 }
 backend "s3" {
   bucket =  "remotebackendtf"
   key    =  "terraform.tfstate"
   region =  "us-east-1"
 }
}
```
Make sure you have a bucket named **remotebackendtf** in **us-east-1** region (You can change the bucket name and region if required, make sure to update the values in the configuration accordingly).
<br/>

> **⚠️ BE WARNED :** This tutorial will create resources in your AWS account for which you may be billed for.

<br />

## 🚀 Execution

Once the setup is complete run the below commands in the downloaded folder:
```
$ terraform init

$ terraform apply -auto-approve
```
After the commands run successfully, the output console will give you an API endpoint and an API Key. You will get an output similar to what is shown below:
```
base_url = https://1rlenzzkv2.execute-api.us-east-1.amazonaws.com/test
api_key  = G7GwSKFCQcKSapomJYlw17qCbEqsfmZ7iBlh6evd
```
Make a note of these values as we will use these later to interact with DynamoDB.

If you go to your AWS account , you will find two lambda functions deployed, **csv-2-dynamodb-lambda-func** and **csv-2-dynamodb-rest-api** (with an API Gateway as the frontend). Terraform also deploys a bucket named **csv-2-dynamodb-bucket** where we will upload our .csv files for testing and a DynamoDB table named **Customers** which has **Id** as it's key attribute.
<br/>

> **📝 Note** : The configuration creates an administrator role and attaches it to the above lambda functions. This makes sure that lambda can read files from S3 and add entries to DynamoDB.

<br />

## 🧐 Testing

Run the following command to upload the sample csv file to s3:
```
$ aws s3 cp sample_csv/sample_data.csv s3://csv-2-dynamodb-bucket/sample_data.csv
```
Run the following command to read the entries from DynamoDB
```
$ aws dynamodb scan --table-name Customers
```
You should find the below 4 entries
```
1	Peter	Parker	9999999999
2	Tony	Stark	9999999999
3	Steve	Rogers	9999999999
4	Nick	Fury	9999999999
```

<br />

## 🌐 Working with the REST API
We will use the API endpoint and the API Key that we got earlier when ```terraform apply``` executed successfully.

You can use the POSTMAN tool to test this API. I've kept the lambda function code for **csv-2-dynamodb-rest-api** very simple. Feel free to modify the code and redeploy as needed.

Below are the formats for different requests that you can use to test the REST API from POSTMAN tool. Make sure to include **x-api-key** header in all your requests.

Create Item:
```
URL: https://1rlenzzkv2.execute-api.us-east-1.amazonaws.com/test
Request Type: POST
Header: x-api-key = G7GwSKFCQcKSapomJYlw17qCbEqsfmZ7iBlh6evd
Body:
{
	"id":  11,
	"firstname":  "testfirstname",
	"lastname":  "testlastname",
	"contact":  9999999999
}
```
Read Item:
```
URL: https://1rlenzzkv2.execute-api.us-east-1.amazonaws.com/test?id=1
Request Type: GET
Header: x-api-key = G7GwSKFCQcKSapomJYlw17qCbEqsfmZ7iBlh6evd
```
Update Item:
```
URL: https://1rlenzzkv2.execute-api.us-east-1.amazonaws.com/test
Request Type: PUT
Header: x-api-key = G7GwSKFCQcKSapomJYlw17qCbEqsfmZ7iBlh6evd
Body:
{
	"id":  1,
	"firstname":  "testfirstname",
	"lastname":  "testlastname",
	"contact":  9999999999
}
```
Delete Item:
```
URL: https://1rlenzzkv2.execute-api.us-east-1.amazonaws.com/test?id=1
Request Type: DELETE
Header: x-api-key = G7GwSKFCQcKSapomJYlw17qCbEqsfmZ7iBlh6evd
```

<br />

## 🚮 Destroy Resources

Once you're done with the testing it's important to remove all the resources that were created as a part of this tutorial so that we don't get charged for them.

Firstly, we need to empty the S3 bucket:
```
$ aws s3 rm s3://csv-2-dynamodb-bucket --recursive
```

Then run the below command to remove all the resources:
```
$ terraform destroy -auto-approve
```
And that's it!!
