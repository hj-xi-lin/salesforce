/*
 *      @author Arun Kumar
 *      @date   10-Mar-2022
 *      @description   Data Factory class to generate test data
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      Arun Kumar                      02-May-2022         Included createNewUsers() for RO-879
 * 
 */

@isTest
public class TestDataFactory {
    
    public static List<Account> createNewAccount(Integer count){

        List<Account> testAccountList = new List<Account>();
        for(Integer i=0;i<count;i++){
            Account acc = new Account();
            acc.Name ='TEST ACCOUNT'+i;
            acc.Service_Country__c = 'DE';
            acc.NumberOfEmployees = 2500+i;
            testAccountList.add(acc);
        }

        return testAccountList;
    }

    public static List<User> createNewUsers(Integer count){
        Profile p = [select id from profile where name='System Administrator'];
        List<UserRole> roleList = [SELECT Id FROM UserRole WHERE Name = 'Salesforce Administrator'];
        List<User> testUserList = new List<User>();
        for(Integer i=0;i<count;i++){
            User u = new User();
            u.alias = 'standt';
            u.email='standarduserTestData@testorg.com';
            u.emailencodingkey='UTF-8';
            u.lastname='Testing'+i;
            u.languagelocalekey='en_US';
            u.localesidkey='en_US';
            u.profileid = p.Id;
            u.timezonesidkey='America/Los_Angeles';
            u.username='standarduser'+i+'TestData@testorg.com';
            u.UserRoleId = roleList[0].Id;
            testUserList.add(u);
        }
        return testUserList;
    }
}