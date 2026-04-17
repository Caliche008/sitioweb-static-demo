provider "aws" {
  region = "us-east-1"
}

terraform {
  backend "s3" {
    bucket  = "caliche-remotestate-pro"
    key     = "caliche-proyecto/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}

resource "aws_s3_bucket" "web" {
  bucket = "caliche-web-static-2026-pro"
}

resource "aws_s3_bucket_website_configuration" "web_config" {
  bucket = aws_s3_bucket.web.id
  index_document {
    suffix = "index.html"
  }
}

# Desbloqueamos el acceso público
resource "aws_s3_bucket_public_access_block" "web_public" {
  bucket = aws_s3_bucket.web.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# La política ahora espera a que el bloqueo se quite (Esto quita el error 403)
resource "aws_s3_bucket_policy" "public_read" {
  depends_on = [aws_s3_bucket_public_access_block.web_public]
  
  bucket = aws_s3_bucket.web.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.web.arn}/*"
    }]
  })
}

resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.web.id
  key          = "index.html"
  source       = "../app/index.html"
  content_type = "text/html"
  # ESTA LINEA ES NUEVA: Fuerza la actualización si el contenido cambia
  etag         = filemd5("../app/index.html") 
}