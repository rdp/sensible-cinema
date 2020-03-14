find ./sessions -type f '!' -exec grep -q "user_id" {} \; -delete
