variable "base_services_image" {
    default = {
      ap-northeast-1 = "ami-19d5f77e"
      ap-northeast-2 = "ami-e1cc1e8f"
      ap-southeast-1 = "ami-1b1ba578"
      ap-southeast-2 = "ami-83b9b7e0"
      eu-central-1 = "ami-61db090e"
      eu-west-1 = "ami-42b08a24"
      sa-east-1 = "ami-45a2c029"
      us-east-1 = "ami-1371fc05"
      us-east-2 = "ami-dd83a7b8"
      us-west-1 = "ami-29062349"
      us-west-2 = "ami-15920175"
    }
}

variable "builder_image" {
    default = {
      ap-northeast-1 = "ami-38d8fa5f"
      ap-northeast-2 = "ami-5ff22031"
      ap-southeast-1 = "ami-381aa45b"
      ap-southeast-2 = "ami-76bab415"
      eu-central-1 = "ami-46d50729"
      eu-west-1 = "ami-c8b288ae"
      sa-east-1 = "ami-af5c3ec3"
      us-east-1 = "ami-4d75f85b"
      us-east-2 = "ami-b78ca8d2"
      us-west-1 = "ami-8d0124ed"
      us-west-2 = "ami-feef7c9e"
    }
}