
with AWS.Response;
with AWS.Status;
with AWS.Dispatchers;
with Ada.Finalization;
with Ada.Text_IO;
with Ada.Strings.Unbounded;

package Page_CB is

	use AWS;
	use AWS.Status;
	use Ada.Strings.Unbounded;

	type District_Page is new Dispatchers.Handler with private;

	overriding function Dispatch
		(This : in District_Page;
		Request : in Status.Data) return Response.Data;

	-- overriding procedure Finalize (This : in out District_Page);
	-- overriding procedure Initialize (This : in out District_Page);

	procedure Init(This : in out District_Page; I : Natural; D : String);
	procedure Clean(This : in out District_Page);

	function Is_Initialized(This : in District_Page) return Boolean;

private

	overriding function Clone (Element : in District_Page) return District_Page;

	function String_ID (This : in District_Page) return String;

	type District_Page is new Dispatchers.Handler with record
		JSON_File_Name : Unbounded_String;
		Id : Natural;
		Initialized : Boolean := False;
	end record;

	Num : Integer := 0;

end Page_CB;