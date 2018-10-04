# Secrets Parser

This gem parse the secrets reading a field in a JSON file, download the encrypted secrets file from S3 and change the values for the encrypted ones.

## Usage

For using correctly this gem, we will need 4 basic things: a JSON file to parse, an S3 bucket and a JSON file encrypted with a AWS KMS key that will store the secret values.

#### JSON File to parse

This file is where there are going to be the references to the secrets in S3. Example:

```
{
    "variables": {
      "MY_SECRET": "secret:bucket_name/path:my_secret",
      "OTHER_SECRET": "secret:bucket_name/path:other_secret"
    }
}
```

The example has 2 secrets in it, these references have 3 parts:

* `secret:` : This is needed to let the gem idetify that the value is a reference to a secret.
* `bucket_name/path` : Path where is located the secret file, bucket_name + path, the extension of the file is inside the gem and it's `json.encrypted`, so in this case, there is a file in this bucket named *secret-testing.json.encrypted*.
* `:my_secret` and `:other_secret` : That's the key that's inside the encrypted file.

*This allow us to let the secret managers decide where to put those secrets*

#### KMS Key

AWS KMS key used to encrypt the secrets and the S3 bucket where secrets are going to be stored.

#### S3 Bucket

Just a AWS S3 Bucket, it's recommended to have it encrypted at rest too with the same KMS key.

#### Encrypted JSON file

Here is where secrets are going to be stored, a simple JSON with all the keys and secrets. Example:

```
{
  "my_secret": "This is a secret weeee",
  "other_secret": "PINCODE: 12345"
}
```

After configuring it, encrypt it with:
```
aws kms encrypt --key-id $YOUR_KMS_KEY_ID --plaintext fileb://YOUR_FILE.json --output text --query CiphertextBlob | base64 --decode > YOUR_FILE.json.encrypted
```

After that, upload it to your S3 and copy the reference in your JSON.

### Usage example

First, set the AWS credentials needed for accesing the S3 bucket and decrypting files.

**Ruby example code:**

```
#!/usr/bin/env ruby

require 'bundler/setup'
require 'secrets_parser'
require 'aws-sdk-s3'

file_json = './app.json' #Path to your json file to be parsed, now using the described in the example
field_to_parse = 'variables' # Field to parse

parser = Secrets::Parser.new
parser.set_config do |config|
  config[:s3_client] = Aws::S3::Client.new(region: ENV['AWS_DEFAULT_REGION'])
  config[:kms_client] = Aws::KMS::Client.new(region: ENV['AWS_DEFAULT_REGION'])
end

parsed_file = parser.parse(file_json, field_to_parse)

puts JSON.pretty_generate(parsed_file)

```

**Output:**

```
{
  "variables": {
    "my_secret": "This is a secret weeee",
    "other_secret": "PINCODE: 12345"
  }
}
```

### Logging

To enable logging feature just configure `:logger` key injecting a logger that implements [Logger interface](https://ruby-doc.org/stdlib-2.5.0/libdoc/logger/rdoc/Logger.html).

Sample using ruby's Logger stdlib:

```
require 'secrets_parser'
require 'logger'

parser = Secrets::Parser.new
parser.set_config do |config|
  config[:logger] = Logger.new(STDOUT)
end
```
