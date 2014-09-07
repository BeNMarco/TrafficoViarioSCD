
with AWS.Response;
with AWS.Status;
with AWS.Dispatchers;

package Page_CB is

	use AWS;
	use AWS.Status;

	function Provide_Home_Page (Request : Status.Data) return Response.Data;

	type Static_Page is new Dispatchers.Handler with private;

	overriding function Dispatch
		(Handler : in Static_Page;
		Request : in Status.Data) return Response.Data;

    procedure Set_Data(Handler : in out Static_Page; D : String);
	procedure Set_Id(Handler : in out Static_Page; I : Natural);

private

	overriding function Clone (Element : in Static_Page) return Static_Page;

	type Static_Page is new Dispatchers.Handler with record
		Data : String(1 .. 255) := (others => ' ');
		Id : Natural;
	end record;

end Page_CB;
