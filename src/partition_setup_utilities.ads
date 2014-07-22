with GNATCOLL.JSON;

with strade_common.strade_features;

use GNATCOLL.JSON;

use strade_common.strade_features;

package partition_setup_utilities is

   function create_array_strade(json_roads: JSON_array) return ptr_strade_urbane_features;

end partition_setup_utilities;
