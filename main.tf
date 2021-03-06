resource "aws_s3_bucket" "sample-crl-ag" {
    bucket = "sample-crl-ag"
}

resource "aws_s3_bucket" "sample-crl-ag-sub" {
    bucket = "sample-crl-ag-sub"
}

data "aws_iam_policy_document" "acmpca_bucket_access" {
    statement {
        actions = [
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:PutObject",
        "s3:PutObjectAcl",
        ]

        resources = [
        aws_s3_bucket.sample-crl-ag.arn,
        "${aws_s3_bucket.sample-crl-ag.arn}/*",
        ]

        principals {
        identifiers = ["acm-pca.amazonaws.com"]
        type        = "Service"
        }
    }
}

resource "aws_s3_bucket_policy" "sample-crl-ag" {
    bucket = aws_s3_bucket.sample-crl-ag.id
    policy = data.aws_iam_policy_document.acmpca_bucket_access.json
}

data "aws_iam_policy_document" "acmpca_bucket_sub_access" {
    statement {
        actions = [
        "s3:GetBucketAcl",
        "s3:GetBucketLocation",
        "s3:PutObject",
        "s3:PutObjectAcl",
        ]

        resources = [
        aws_s3_bucket.sample-crl-ag-sub.arn,
        "${aws_s3_bucket.sample-crl-ag-sub.arn}/*",
        ]

        principals {
        identifiers = ["acm-pca.amazonaws.com"]
        type        = "Service"
        }
    }
}

resource "aws_s3_bucket_policy" "sample-crl-ag-sub" {
    bucket = aws_s3_bucket.sample-crl-ag-sub.id
    policy = data.aws_iam_policy_document.acmpca_bucket_sub_access.json
}




resource "aws_acmpca_certificate_authority" "example-root" {
    certificate_authority_configuration {
        key_algorithm     = "RSA_4096"
        signing_algorithm = "SHA512WITHRSA"

        subject {
        common_name = "example.com"
        }
    }

    enabled = true

    revocation_configuration {
        crl_configuration {
        custom_cname       = "crl.example.com"
        enabled            = true
        expiration_in_days = 7
        s3_bucket_name     = aws_s3_bucket.sample-crl-ag.id
        }
    }

    type = "ROOT"

    depends_on = [aws_s3_bucket_policy.sample-crl-ag]
}



resource "aws_acmpca_certificate_authority" "example-subordinate" {
    certificate_authority_configuration {
        key_algorithm     = "RSA_4096"
        signing_algorithm = "SHA512WITHRSA"

        subject {
        common_name = "sub.example.com"
        }
    }

    enabled = true

    revocation_configuration {
        crl_configuration {
        custom_cname       = "crl.sub.example.com"
        enabled            = true
        expiration_in_days = 7
        s3_bucket_name     = aws_s3_bucket.sample-crl-ag-sub.id
        }
    }

    type = "SUBORDINATE"

    depends_on = [aws_s3_bucket_policy.sample-crl-ag-sub]
}