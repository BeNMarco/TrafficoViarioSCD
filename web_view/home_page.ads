with AWS.Response;
with AWS.Status;
with AWS.Dispatchers;

with Page_CB;
with Districts_Repository;

use Districts_Repository;

package Home_Page is

	use AWS;
	use AWS.Status;

	type Registered_Districts_Type is array (Natural range <>) of Boolean;
	type Home_Page_Handler(Num : Natural) is new Dispatchers.Handler with private;

	overriding function Dispatch
		(This : in Home_Page_Handler;
		Request : in Status.Data) return Response.Data;
		
	procedure Set_Districts_Repository(This : in out Home_Page_Handler; R : Access_Districts_Repository_Interface);

private

	overriding function Clone (This : in Home_Page_Handler) return Home_Page_Handler;

	type Home_Page_Handler(Num : Natural) is new Dispatchers.Handler with record
		Max_Num_Districts : Natural := Num;
		Registered_Districts : Registered_Districts_Type(1 .. Num);
		Districts_Repository : Access_Districts_Repository_Interface;
	end record;

end Home_Page;
