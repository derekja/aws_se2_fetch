# aws_se2_fetch

just placing some powershell scripts in here that I am using to grab the sentinel-2 imagery from AWS and place it up onto Azure

I am using Powershell 7 preview on a Windows 10 computer, although I don't think anything I'm doing is sensitive to version.

I am going to presume that locally you have AWS credentials as per the AWS powertool instructions here: https://docs.aws.amazon.com/powershell/latest/userguide/pstools-getting-set-up.html

I am going to presume that you have appropriate Azure credentials, and have installed the Azure Powershell package from here: https://docs.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-4.5.0

You'll then need to Connect-AzAccount and authorize from an account with Azure supercluster permissions.

I'm going to bring all data locally just because I don't care enough to spin up a VM on Azure to allow it to just move from cloud to cloud like it should. If you are not at UVic or somewhere else with good internet then you may want to assess the efficiency of that.

The first script, Copy_se.ps1, will connect to AWS and access the requester pays bucket containing the sentinel-2 imagery

It will then iterate through $fn to get the name of each file. Since we are not able to get the full path from the filename we may need to guess a bit.

in the sentinel-s2-l1c bucket the /products folder contains each year, month number without a leading 0, day (again, no leading 0), then filename (which is actually a folder). These folders will be copied to the local se2 subdirectory.

That will log each file copied and keep track of which files could not be found. (well, at some point it should. I just compare the number of rows in the csv with the results folder)

The second script, copy_Az.ps1, will take the contents of the se2 subdirectory and copy it up to the olci/se2 fileshare on Azure. It will then iterate through each of the (actually, just a command line now, such as: azcopy copy 'https://derekja.s3.us-east-1.amazonaws.com/se2_2018_1.csv.results' 'https://olci.blob.core.windows.net/se2?sv=2019-02-02&st=2020-08-12T02%3A52%3A48Z&se=2026-08-13T02%3A52%3A00Z&sr=c&sp=racwdl&sig=bpHtRe2V6tj82fWQ08bdU1RlvphJ8tnrd3OrVZ9QtlM%3D' --recursive=true)

It would be easier and faster to azcopy directly from the bucket to Azure, but I'm not sure how to get it to handle requester pays. (wait, yes I am! Copy the latest AzCopy from here: https://docs.microsoft.com/en-us/azure/storage/common/storage-use-azcopy-v10)

Since the data on AWS is coming out of the EU, btw, it is $.09 USD per GB. So not quite as cheap as hoped. Still assessing overall size.

Sigh, apparently azcopy cannot copy from S3 to a fileshare, but only to a blob. So we'll have to do that. ref: https://github.com/Azure/azure-storage-azcopy/issues/934

OK, this works. Almost. Because the job fails with an access denied, and then needs a slightly different request to use requester pays, I can't seem to get this to work on the requester-pays bucket. Maybe the solution is to load everything into mine and then pull from there. Here is an example of pulling from mine working:

azcopy copy 'https://derekja.s3.us-east-1.amazonaws.com/tmp' 'https://olci.blob.core.windows.net/se2?sv=2019-02-02&st=2020-08-12T02%3A52%3A48Z&se=2026-08-13T02%3A52%3A00Z&sr=c&sp=racwdl&sig=<redacted>' --recursive=true


So.. may need to use the aws powershell tools to go through the list and copy each to my bucket, then from there can move over to Azure

Sigh, but the powershell aws client also doesn't handle requester pays buckets very well. Going to have to drop all the way down to the AWS cli tools. https://aws.amazon.com/cli/ This means that I do have to bring the files either local or into my own bucket first. I think I'll move them to my own bucket.

OK, for instance this cli command copies a file from the se2 bucket to a /tmp directory on my derekja bucket:

 aws s3 cp 's3://sentinel-s2-l1c/products/2018/8/30/S2B_MSIL1C_20180830T192859_N0206_R142_T09UXQ_20180830T231740' 's3://derekja/tmp/' --recursive --request-payer 'requester'

 (but it puts the contents of the above directory into tmp. Need to get that directory name and put it together a bit better first...)

 OK, sorted. In a single column csv it now creates a bucket with that name.results in my S3 account and I can then move that over to Azure in bulk for each query.

 PS C:\Users\derek\aws_se2_fetch> .\Copy_se.ps1 se2_2018_2.csv

 azcopy copy 'https://derekja.s3.us-east-1.amazonaws.com/se2_2018_1.csv.results' 'https://olci.blob.core.windows.net/se2?sv=2019-02-02&st=2020-08-12T02%3A52%3A48Z&se=2026-08-13T02%3A52%3A00Z&sr=c&sp=racwdl&sig=bpHtRe2V6tj82fWQ08bdU1RlvphJ8tnrd3OrVZ9QtlM%3D' --recursive=true




