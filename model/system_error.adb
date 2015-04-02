

package body System_error is

   protected body log_system_error is
      procedure set_error(tipo: type_error; set: in out Boolean) is
      begin
         if error=False then
            set:= True;
         else
            set:= False;
         end if;
         error:= True;
      end set_error;
      procedure set_message_error(message: Unbounded_String) is
      begin
         message_error:= message;
      end set_message_error;
      function is_in_error return Boolean is
      begin
         return error;
      end is_in_error;

   end log_system_error;

end System_error;
