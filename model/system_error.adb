with Ada.Text_IO;

with data_quartiere;
with the_name_server;

use Ada.Text_IO;

use data_quartiere;
use the_name_server;

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

      --function all_tasks_are_exit return Boolean is
      --begin
      --   if num_task_finished=get_num_task then
      --      return True;
      --   end if;
      --   return False;
      --end all_tasks_are_exit;

      procedure add_finished_task(id_task: Positive) is
      begin
         num_task_finished:= num_task_finished+1;
         if num_task_finished=get_num_task then
            quartiere_has_closed_tasks(get_id_quartiere);
         end if;
      end add_finished_task;

   end log_system_error;

end System_error;
