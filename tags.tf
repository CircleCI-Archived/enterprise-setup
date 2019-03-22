locals {
  common_tags = "${map(
    "ce_email", "YOU@circleci.com",
    "ce_purpose", "Some Reason",
    "ce_schedule", "core hours",
    "ce_duration", "peristent"
  )}"

  ///needed for ASGs until 0.12 - https://github.com/hashicorp/terraform/issues/2283#issuecomment-418544222
  common_tags_list = [
    "${map("key","ce_email", 
      "value", "YOU@circleci.com", 
      "propagate_at_launch",true)}"
  ]
}

