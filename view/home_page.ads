
with AWS.Response;
with AWS.Status;
with AWS.Dispatchers;

package Home_Page is

	use AWS;
	use AWS.Status;

	type Home_Page_Handler is new Dispatchers.Handler with private;

	overriding function Dispatch
		(This : in Home_Page_Handler;
		Request : in Status.Data) return Response.Data;

private

	overriding function Clone (Element : in Home_Page_Handler) return Home_Page_Handler;

	type Home_Page_Handler is new Dispatchers.Handler with null	record;
	--	WebS : WebServer_Wrapper_Type;
	-- end record;

end Home_Page;
