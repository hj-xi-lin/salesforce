global class createAutomatedTasks implements Database.Batchable<sObject>  {
    
    global final Integer quarter;    // variable to hold Current quarter
    global final String query;      // Variable to hold final query string
    
    // Constructor for Initialization 
    global createAutomatedTasks(string q, Integer qtr) {
        this.query = q;
        this.quarter = qtr;
    }
    
    // Fetch the Records based on given query
    global Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext bc, List<Account> scope) {
        if(!scope.isEmpty()) {
            system.debug('--Total Accounts-->>'+scope.size());
            List<Task> taskToBeInsert = new list<Task>();
            try {
                for(Account acc : scope) 
                {
                    if(quarter == 4) {
                        //if(acc.Potential__c.equalsIgnoreCase('Cash Cows')) {
                        //List<string> subList = new List<String>{'Terminiere Deinen Jour-Fixe'};
                        //for(Integer i = 0; i < subList.size(); i++) {
                                    Task t = new Task();
                                    t.OwnerId = acc.OwnerId;
                                    t.ActivityDate = Date.today().addDays(7);
                                    t.WhatId = acc.Id;
                                    t.Subject = 'Terminiere Deinen Jour-Fixe';
                                    taskToBeInsert.add(t);
                                //}
                        /*} else {
                            Task t = new Task();
                            t.OwnerId = acc.OwnerId;
                            t.Subject = 'Terminiere Dein Jahresgesprach';
                            t.ActivityDate = Date.today().addDays(7);
                            t.WhatId = acc.Id;
                            taskToBeInsert.add(t);
                        }*/
                    } 
                    /*else if(quarter == 1 || (quarter == 2 && !acc.Potential__c.equalsIgnoreCase('Cash Cows')) || quarter == 3) {
                        Task t = new Task();
                        t.OwnerId = acc.OwnerId;
                        t.Subject = 'Terminiere Deinen Jour-Fixe';
                        t.ActivityDate = Date.today().addDays(7);
                        t.WhatId = acc.Id;
                        taskToBeInsert.add(t);
                    }*/
                }
                if(!taskToBeInsert.isEmpty()) {
                  system.debug('--Total Tasks-->'+taskToBeInsert.size());
                    Insert taskToBeInsert;
                }
            } catch(exception e) {
                system.debug('--Error Caused by-->'+e.getCause());
                system.debug('--Error Message-->'+e.getMessage());
                system.debug('--Error Line Number-->'+e.getLineNumber());
                system.debug('--Error Traces-->'+e.getStackTraceString());
            }
        }
    }
    
    global void finish(Database.BatchableContext bc) {
    }
}