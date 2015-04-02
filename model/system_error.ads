with Ada.Strings.Unbounded;
use Ada.Strings.Unbounded;
package System_error is

   system_error_exc: exception;
   propaga_error: exception;

   type type_error is (name_server,server,quartiere,webserver,conf_json_quartiere,altro,begin_propagazione_errore);

   protected log_system_error is
      procedure set_error(tipo: type_error; set: in out Boolean);
      procedure set_message_error(message: Unbounded_String);
      function is_in_error return Boolean;
   private
      error: Boolean:= False;
      message_error: Unbounded_String;
      tipo_errore: type_error;
   end log_system_error;

end System_error;
