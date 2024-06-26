#!/usr/bin/env bash

set -euo pipefail

SOURCES_REPO_NAME="RakuyoKit/swift"
TOOL_NAME="swift-style-guide"

fail() {
	echo -e "asdf-$TOOL_NAME: $*"
	exit 1
}

sort_versions() {
	sed 'h; s/[+-]/./g; s/.p\([[:digit:]]\)/.z\1/; s/$/.z/; G; s/\n/ /' |
  		LC_ALL=C sort -t. -k 1,1 -k 2,2n -k 3,3n -k 4,4n -k 5,5n | awk '{print $2}'
}

list_all_versions() {
	git ls-remote --tags --refs "https://github.com/${SOURCES_REPO_NAME}" |
		grep -o 'refs/tags/.*' | cut -d/ -f3- |
	  	sed 's/^v//'
}

download_style_file() {
	local version=$1
	local url_path=$2
	local url="https://raw.githubusercontent.com/${SOURCES_REPO_NAME}/${version}/${url_path}"

	echo "Will download: ${url}"

	curl -O -L "${url}"
}

install_version() {
	local install_type="$1"
	local version="$2"

	if [ "$install_type" != "version" ]; then
		fail "asdf-$TOOL_NAME supports release installs only"
	fi

	local install_path="./swift"
	local sources_path="./Sources"

	(
		# Rakefile
		current_script_path=${BASH_SOURCE[0]}
		plugin_dir=$(dirname "$(dirname "$current_script_path")")
		cp -f "${plugin_dir}/lib/Rakefile" Rakefile

		# xcode_settings.bash
		mkdir -p "${install_path}" && cd ${install_path}
		download_style_file "${version}" "resources/xcode_settings.bash"

		mkdir -p ${sources_path} && cd ${sources_path}

		# swiftlint.yml
		download_style_file "${version}" "Sources/RakuyoSwiftFormatTool/swiftlint.yml"

		# rakuyo.swiftformat
		download_style_file "${version}" "Sources/RakuyoSwiftFormatTool/rakuyo.swiftformat"

		echo "$TOOL_NAME $version installation was successful!"
	) || (
		rm -rf "$install_path"
		fail "An error occurred while installing $TOOL_NAME $version."
	)
}
