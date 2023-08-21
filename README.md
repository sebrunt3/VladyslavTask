Requirements

The handler is designed assuming that there's already a trigger framework in place that invokes the provided methods based on trigger events.
The solution requires the custom junction object AccountContactRelationship__c to establish the relationship between Contacts and Accounts.

Testing

The solution is thoroughly tested using the Salesforce Apex Test framework. Unit tests have been designed to cover various scenarios including insertions, updates, deletions, bulk processing, and edge cases.

Installation

Deploy the AccountOwnersSharingHandler class to your Salesforce environment.
Ensure that the necessary custom objects and fields (AccountContactRelationship__c, RelatedAccountOwner__c) are present.
Integrate the provided handler methods into your existing trigger framework, ensuring proper invocation based on trigger events.

Limitations

The solution is designed to handle mass updates of up to 50 records at a time.
The solution respects Salesforce governor limits, but ensure proper testing under various scenarios to avoid unexpected behavior.
