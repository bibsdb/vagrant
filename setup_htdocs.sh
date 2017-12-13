mkdir htdocs
cd htdocs
git clone -b "v2.1.8" git@github.com:search-node/search_node.git search_node

git clone -b "v4.2.2" git@github.com:os2display/docs.git docs
git clone git@github.com:bibsdb/admin.git admin
git clone -b "v4.2.2" git@github.com:os2display/middleware.git middleware
git clone -b "v4.2.2" git@github.com:os2display/screen.git screen
git clone -b "v4.2.2" git@github.com:os2display/styleguide.git styleguide

cd ..
