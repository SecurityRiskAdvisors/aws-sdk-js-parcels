#!/bin/bash
set -euo pipefail
read -r tarball_url commit_url <<<"$(curl https://api.github.com/repos/aws/aws-sdk-js/tags?per_page=1 2> /dev/null | grep -P '"url"|"tarball_url"' | grep -o -P 'https[^"]+'| paste -d' ' - -)"
commit_time=$(date -d"$(curl "${commit_url}" 2>/dev/null | grep '"date"'  | sort -bfgu | tail -1 | grep -P -o '[\d]{4}[^"]+')" "+%s")
reference_time=$(date -d'1 week ago' "+%s")
if [[ "${commit_time}" -gt "${reference_time}" ]]; then
	wget -O aws-repo.tgz "${tarball_url}"
	mkdir -p aws-sdk-js
	tar zxf aws-repo.tgz -C "$(readlink -f aws-sdk-js)" --strip-components=1
	docker pull node
	docker run -v "$(readlink -f aws-sdk-js)":/aws-sdk-js -i --rm node /bin/bash 2> >(tee -a aws-sdk-parcels-err.log >&2) 1> aws-sdk-s3-2006-03-01.js <<- EOF
		cd /aws-sdk-js 1>&2
		npm install 1>&2
		MINIFY=1 node dist-tools/browser-builder.js s3-2006-03-01
		echo "STATUS: Completed build." >&2
		exit
EOF
fi
rm -v -f aws-repo.tgz 1>&2
rm -v -rf aws-sdk-js/ 1>&2
