
with AWS.Response;
with AWS.Status;
with AWS.Dispatchers;

package JS_Page_Compiler is

	use AWS;
	use AWS.Status;

	type JS_Page_Compiler_Handler is new Dispatchers.Handler with private;

	overriding function Dispatch
		(Handler : in JS_Page_Compiler_Handler;
		Request : in Status.Data) return Response.Data;

private

	overriding function Clone (Element : in JS_Page_Compiler_Handler) return JS_Page_Compiler_Handler;

	type JS_Page_Compiler_Handler is new Dispatchers.Handler with null record;

end JS_Page_Compiler;
