Steps:
1.Create a webiste file
2.Update into repository
3. Enter AWS IAM dashboard and create a user with programatic access that's required to run the commands to aws console via github action.
Assign it to AWS-S3-FullAccess
Limit permissions by tags - use this one 
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::your-bucket-name",
        "arn:aws:s3:::your-bucket-name/*"
      ]
    }
  ]
}

Then generate access key - Security credentials -> access keys -> generate access key
Save the credential in a save place !!
4.Create a pipeline thats going propagate the changes afer each change for the repo's files
