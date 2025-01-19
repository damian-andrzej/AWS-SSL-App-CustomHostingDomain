# Automate File Updates to an S3 Bucket Using GitHub Actions

This guide explains how to create a GitHub Actions pipeline to automatically propagate changes to an S3 bucket after repository file updates.

## Steps

### 1. Create a Website File
- Develop the files for your website or application (e.g., `index.html`, `style.css`, etc.).

### 2. Update Files into the Repository
- Push your website files to your GitHub repository:
  ```bash
  git add .
  git commit -m "Add website files"
  git push origin main
  ```
  *(Replace `main` with your target branch if needed.)*

### 3. Configure AWS IAM for Programmatic Access
1. Log in to the **AWS Management Console**.
2. Navigate to the **IAM Dashboard**.
3. **Create a User**:
   - Click **Users** > **Add Users**.
   - Enter a username (e.g., `github-actions`).
   - Select **Programmatic access**.
4. **Assign Permissions**:
   - Attach the **AmazonS3FullAccess** policy to the user.
   - For limiting permissions by tags, use the following JSON policy:
     ```json
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
     ```
     *(Replace `your-bucket-name` with the name of your S3 bucket.)*
5. **Generate Access Keys**:
   - Go to **Security credentials** > **Access keys**.
   - Click **Create access key** and download the credentials.
   - **Save the credentials securely**, as the secret key cannot be viewed again.

### 4. Create a GitHub Actions Pipeline
1. **Set up GitHub Secrets**:
   - Go to your repository: **Settings** > **Secrets and variables** > **Actions**.
   - Add the following secrets:
     - `AWS_ACCESS_KEY_ID`: Your AWS Access Key ID.
     - `AWS_SECRET_ACCESS_KEY`: Your AWS Secret Access Key.
     - `S3_BUCKET_NAME`: Your bucket name.

2. **Define the Workflow**:
   Create a `.github/workflows/main.yml` file in your repository and add the following configuration:
   ```yaml
   name: Update S3 Bucket on Change

   on:
     push:
       branches:
         - main  # Replace with your target branch

   jobs:
     deploy-to-s3:
       runs-on: ubuntu-latest

       steps:
         # Checkout the repository
         - name: Checkout Code
           uses: actions/checkout@v3

         # Set up AWS CLI
         - name: Configure AWS CLI
           uses: aws-actions/configure-aws-credentials@v3
           with:
             aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
             aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
             aws-region: us-east-1  # Replace with your AWS region

         # Sync files to S3 bucket
         - name: Sync files to S3
           run: |
             aws s3 sync . s3://${{ secrets.S3_BUCKET_NAME }} --delete
   ```

3. **Commit and Push the Workflow**:
   - Save the file and push it to your repository:
     ```bash
     git add .github/workflows/s3-sync.yml
     git commit -m "Add GitHub Actions pipeline for S3 sync"
     git push origin main
     ```

---

### Summary
Now, every time you push changes to your repository, the GitHub Actions workflow will automatically update the specified S3 bucket with the latest files.

Make sure your AWS credentials and bucket settings are correct to avoid permission 
