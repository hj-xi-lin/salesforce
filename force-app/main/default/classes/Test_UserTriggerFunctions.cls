/*
 *      @author Arun Kumar
 *      @date   02-May-2022
 *      @description Test class for UserTriggerFunctions
 *
 *      Modification Log:
 *      ------------------------------------------------------------------------------------
 *      Developer                       Date                Description
 *      ------------------------------------------------------------------------------------
 *      Arun Kumar                  02-May-2022             Created for RO-879
 * 
 */

@isTest
public with sharing class Test_UserTriggerFunctions {
    @isTest
    static void test_checkServiceCountry(){
        Test.startTest();
        //To test new user creation
        List<User> testUserList = TestDataFactory.createNewUsers(2);
        insert testUserList;
        
        //To test role update for old users
        List<Profile> profileList = [SELECT Id FROM Profile WHERE Name = 'Agency Manager'];
        List<UserRole> roleList = [SELECT Id FROM UserRole WHERE Name = 'Agency Manager'];
        testUserList[1].UserRoleId = roleList[0].Id;
        testUserList[1].ProfileId =  profileList[0].Id;
        update testUserList;
        Test.stopTest();
    }
}