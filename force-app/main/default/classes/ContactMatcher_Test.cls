@isTest
public with sharing class ContactMatcher_Test {
    public ContactMatcher_Test() {

    }
    @TestSetup
    static void makeData(){
        Contact c1 = new Contact(FirstName='John',LastName='Snow');
        Contact c2 = new Contact(FirstName='Johnny',LastName='Snow');
        Contact c3 = new Contact(FirstName='John',LastName='Snowden');
        Contact c4 = new Contact(FirstName='Johnathan',LastName='Snowdenson');
        insert new List<Contact>{c1,c2,c3,c4};
    }
    @isTest
    static void testMatcher(){
        Contact c = [SELECT ID FROM Contact WHERE FirstName='John' AND LastName='Snow'];
        List<Contact> cons = [SELECT ID FROM Contact];
        List<Id> conIds = new List<Id>();
        for (Integer i = 0; i < cons.size(); i++) {
            conIds.add(cons[i].Id);
        }
        Test.setFixedSearchResults(conIds);
        ContactMatcher.FlowInput dataIn = new ContactMatcher.FlowInput();
        dataIn.firstName='John';
        dataIn.lastName='Snow';
        dataIn.minMatchPCT=80;
        Test.startTest();
        List<ContactMatcher.FlowOutput> dataOuts = ContactMatcher.start(new List<ContactMatcher.FlowInput>{dataIn});
        Test.stopTest();
        system.assertEquals(c.Id, dataOuts[0].contactId);
    }
    @isTest
    static void testMatcherDeepSearch(){
        Contact c = [SELECT ID FROM Contact WHERE FirstName='John' AND LastName='Snow'];
        List<Contact> cons = [SELECT ID FROM Contact];
        List<Id> conIds = new List<Id>();
        for (Integer i = 0; i < cons.size(); i++) {
            conIds.add(cons[i].Id);
        }
        Test.setFixedSearchResults(conIds);
        ContactMatcher.FlowInput dataIn = new ContactMatcher.FlowInput();
        dataIn.firstName='John';
        dataIn.lastName='Snow';
        dataIn.minMatchPCT=80;
        dataIn.deepSearch=true;
        Test.startTest();
        List<ContactMatcher.FlowOutput> dataOuts = ContactMatcher.start(new List<ContactMatcher.FlowInput>{dataIn});
        Test.stopTest();
        system.assertEquals(c.Id, dataOuts[0].contactId);
    }
    @isTest
    static void testMatcherFailure(){
        ContactMatcher.FlowInput dataIn = new ContactMatcher.FlowInput();
        dataIn.firstName='John';
        dataIn.lastName='Snow';
        dataIn.minMatchPCT=80;
        Test.startTest();
        List<ContactMatcher.FlowOutput> dataOuts = ContactMatcher.start(new List<ContactMatcher.FlowInput>{dataIn});
        Test.stopTest();
        system.assertEquals(null, dataOuts[0].contactId);
    }
    @isTest
    static void testMatcherFailureBlank(){
        ContactMatcher.FlowInput dataIn = new ContactMatcher.FlowInput();
        dataIn.firstName='';
        dataIn.lastName='';
        dataIn.minMatchPCT=80;
        Test.startTest();
        List<ContactMatcher.FlowOutput> dataOuts = ContactMatcher.start(new List<ContactMatcher.FlowInput>{dataIn});
        Test.stopTest();
        system.assertEquals(null, dataOuts[0].contactId);
    }
}