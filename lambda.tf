resource "aws_dynamodb_table" "customer-table" {
  name           = "Customers"
  billing_mode   = "PROVISIONED"
  read_capacity  = 10
  write_capacity = 10
  hash_key       = "Id"

  attribute {
    name = "Id"
    type = "N"
  }
}

resource "aws_iam_role" "iam_for_lambda" {
  name = "${var.function_name}-lambda-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "policy-attach" {
  role       = aws_iam_role.iam_for_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_s3_bucket" "bucket" {
  bucket = "${var.function_name}-bucket"
}

resource "aws_lambda_function" "func" {
  filename      = "zip_files/lambda_csv_2_dynamodb.zip"
  function_name = "${var.function_name}-lambda-func"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_csv_2_dynamodb.lambda_handler"
  runtime       = "python3.8"
  depends_on    = [aws_dynamodb_table.customer-table]
}

resource "aws_lambda_function" "rest_api" {
  filename      = "zip_files/lambda_rest_api.zip"
  function_name = "${var.function_name}-rest-api"
  role          = aws_iam_role.iam_for_lambda.arn
  handler       = "lambda_rest_api.lambda_handler"
  runtime       = "python3.8"
  depends_on    = [aws_lambda_function.func]
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.func.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_lambda_permission" "allow_apigw" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rest_api.arn
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.rest_api.execution_arn}/*/*"
  depends_on    = [aws_api_gateway_rest_api.rest_api]
}

resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.func.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  depends_on = [aws_lambda_permission.allow_bucket]
}