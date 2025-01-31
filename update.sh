#!/bin/bash
set -Eeuo pipefail

declare -A r_versions=(
    [3.1]='3.1.3'
    [3.2]='3.2.5'
    [3.3]='3.3.3'
    [3.4]='3.4.4'
    [3.5]='3.5.3'
    [3.6]='3.6.3'
    [4.0]='4.0.4'
    [devel]='devel'
)

declare -A os_identifiers=(
    [xenial]='ubuntu-1604'
    [bionic]='ubuntu-1804'
    [focal]='ubuntu-2004'
    [centos7]='centos-7'
    [centos8]='centos-8'
    [opensuse42]='opensuse-42'
    [opensuse15]='opensuse-15'
    [opensuse152]='opensuse-152'
)

generated_warning() {
	cat <<-EOH
		#
		# NOTE: THIS DOCKERFILE IS GENERATED VIA "update.sh"
		#
		# PLEASE DO NOT EDIT IT DIRECTLY.
		#

	EOH
}

for version in "${!r_versions[@]}"; do
    for variant in "${!os_identifiers[@]}"; do
        dir="$version/$variant"

        mkdir -p $dir

        case "$variant" in
            xenial|bionic|focal) template='ubuntu'
            ;;
            centos7|centos8) template='centos'
            ;;
            opensuse42|opensuse15|opensuse152) template='opensuse'
            ;;
        esac

        template="Dockerfile-${template}.template"

        { generated_warning; cat "$template"; } > "$dir/Dockerfile"

        sed -ri \
            -e "s/%%VARIANT%%/${variant}/" \
            -e "s/%%R_VERSION%%/${r_versions[$version]}/" \
            -e "s/%%OS_IDENTIFIER%%/${os_identifiers[$variant]}/" \
            "$dir/Dockerfile"

        cp docker-compose.test.yml $dir

        # Add MAJOR.MINOR.PATCH version tags
        mkdir -p "$dir/hooks" && cp post_push.template.sh "$dir/hooks/post_push"
        sed -ri \
            -e "s/%%TAG%%/${r_versions[$version]}-${variant}/" \
            "$dir/hooks/post_push"
    done
done
