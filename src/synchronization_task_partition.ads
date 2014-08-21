


package synchronization_task_partition is

   protected type synchronization_tasks is
      entry registra_task;
      procedure reset;
   private
      num_task_ready: Natural:= 0;
      num_task_to_go: Natural:= 0;
   end synchronization_tasks;

   type ptr_synchronization_tasks is access all synchronization_tasks;

end synchronization_task_partition;
