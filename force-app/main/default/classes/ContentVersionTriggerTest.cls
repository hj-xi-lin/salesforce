@isTest
public with sharing class ContentVersionTriggerTest {

    public static testMethod void testMethod1() {
		
		ContentVersion testContentInsert =new ContentVersion(); 
		testContentInsert.ContentURL='http://www.google.com/'; 
		testContentInsert.Title ='Google.com'; 
		insert testContentInsert; 
	}
	
}