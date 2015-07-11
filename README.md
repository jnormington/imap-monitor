#IMAP Monitor

In most scenarios we rely on email communication from most web applications using it for

- marketing
- updates to T&C
- custom user setup alerts

In all cases there different approaches on how we implement the sending of these emails suchas
 - external companies
 - background processes (different implementation variations)

This allows you to check that; 

a) The external company can handle such loads within a time frame and there are not any email dropouts.

b) If internally sending the background process implementation is the correct for the long term load.

##Limitations

 - You can't rely on any current email host suchas google mail because there is throttling to the one email address in such large volumes. 
 - In this case a postfix
 email server should be setup with a mutt email client on a Ubuntu box for a realistic and un-throttled email receiptant.
