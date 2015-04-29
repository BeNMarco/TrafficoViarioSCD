with Page_CB;

use Page_CB;

package Districts_Repository is

  type Registered_Districts_Type is array (Natural range <>) of Boolean;
  type Districts_Registry_Type is array (Positive range <>) of District_Page;

  type Districts_Repository_Interface is limited interface;
  type Access_Districts_Repository_Interface is access all Districts_Repository_Interface'Class;

  function Get_Districts_Registry(This: in Districts_Repository_Interface) return Districts_Registry_Type is abstract;

end Districts_Repository;
