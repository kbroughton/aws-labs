accountA=111122223333
accountB=444455556666
profileA=pbeta
profileB=pdelta

rand=$RANDOM
cidr_1=54.240.143.0/24
cidr_2=54.240.144.0/24
mybucket1=mybucket1-$rand
mybucket2=mybucket2-$rand
path="/aws-labs/"
roleA1=roleA1-$rand
roleA2=roleA2-$rand
roleB1=roleB1-$rand
roleB2=roleB2-$rand
iam_permission_policy_for_s3_arnA=arn:aws:iam::$accountA:policy${path}iam_permission_policy_for_s3_$rand
iam_permission_policy_for_s3_arnB=arn:aws:iam::$accountB:policy${path}iam_permission_policy_for_s3_$rand