fpk_version=0.1
qinglong_version="debian"
app_version="${fpk_version}-${qinglong_version}"
fpk_name="qinglong-debian-${app_version}.fpk"

echo "开始打包 qinglong-debian.fpk"
fnpack build --directory qinglong-debian/

rm -f "${fpk_name}"
mv qinglong-debian.fpk "${fpk_name}"
echo "打包完成: ${fpk_name}"
