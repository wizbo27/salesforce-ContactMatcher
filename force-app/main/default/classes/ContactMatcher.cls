public without sharing class ContactMatcher {
    
    public class FlowInput{
        @InvocableVariable public String firstName;
        @InvocableVariable public String middleName;
        @InvocableVariable public String lastName;
        @InvocableVariable public Decimal minMatchPCT;
        @InvocableVariable public boolean deepSearch=false;
    }
    public class Match implements Comparable{
        @InvocableVariable public Id contactId;
        @InvocableVariable public Decimal matchPercentage;

        public match(Contact c,Decimal pct){
            this.contactId=c.Id;
            this.matchPercentage=pct;
        }

        public Integer compareTo(Object compareTo) {
			Match compareToMatch = (Match)compareTo;
			if (matchPercentage == compareToMatch.matchPercentage)return 0;	
			if (matchPercentage < compareToMatch.matchPercentage)return 1;	

			return -1;        
		}
    }
 
    public class FlowOutput{
        @InvocableVariable public Id contactId=null;
        @invocableVariable public List<Match> matches = new List<Match>();
    }

    @InvocableMethod
    public static List<FlowOutput> start(List<FlowInput> incoming){
        List<FlowOutput> outgoing = new List<FlowOutput>();
        for(Integer i=0;i<incoming.size();i++){
            outgoing.add(findMatches(incoming[i]));
        }
        return outgoing;
    }

    public static FlowOutput findMatches(FlowInput data){
        FlowOutput out = new FlowOutput();
        Contact matchedContact;
        if(data.minMatchPCT==null) data.minMatchPCT=75;

        //try direct match
        List<Contact> matches;
        matches = getContactsSOSL(data);
        
        if(matches.size() == 0){
            out.matches=null;
            out.contactId=null;
            return out;
        } else {
            for(Integer i=0;i<matches.size();i++){
                Decimal a= calcMatchPCT(matches[i],data);
                out.matches.add(new match(matches[i],a));
            }
        }
        out.matches.sort();
        if(out.matches[0].matchPercentage>data.minMatchPCT)
            out.contactId=out.matches[0].contactId;
        system.debug(out.matches);
        return out;
    }
    
    public static List<Contact> getContactsSOSL(FlowInput data){
        String startOfQuery ='FIND {';
        String baseQuery='';
        if(data.deepSearch){
            if(data.firstName!=null&&!data.firstName.isWhitespace())baseQuery+=data.firstName+' OR ';
            if(data.middleName!=null&&!data.middleName.isWhitespace())baseQuery+=data.middleName+' OR ';
            if(data.lastName!=null&&!data.lastName.isWhitespace())baseQuery+=data.lastName+' OR ';
            baseQuery=baseQuery.removeEnd('OR ');
        }else {
            if(data.firstName!=null&&!data.firstName.isWhitespace())baseQuery+=data.firstName+' ';
            if(data.middleName!=null&&!data.middleName.isWhitespace())baseQuery+=data.middleName+' ';
            if(data.lastName!=null&&!data.lastName.isWhitespace())baseQuery+=data.lastName+' ';
        }
        if (baseQuery.isWhitespace()) {
            return new list<Contact>();
        }
        List<List<Contact>> matches = search.query(startOfQuery+baseQuery+'} IN NAME FIELDS RETURNING CONTACT(ID,FIRSTNAME,MIDDLENAME,LASTNAME)');
        return matches[0];
    }

    public static Decimal calcMatchPCT(contact c,FlowInput data){
        Decimal ret=0;
        Integer dataPoints=0;
        if(data.firstName!=null){
            dataPoints++;
            ret += calcJaroWinklerDistance(data.firstName.toLowerCase(),c.FirstName.toLowerCase());
        }
        if(data.middleName!=null){
            dataPoints++;
            ret += calcJaroWinklerDistance(data.middleName.toLowerCase(),c.MiddleName.toLowerCase());
        }
        if(data.lastName!=null){
            dataPoints++;
            ret += calcJaroWinklerDistance(data.lastName.toLowerCase(),c.LastName.toLowerCase());
        }
        ret = (ret*100)/dataPoints;
        return ret.round();
    }
    public static Decimal calcJaroWinklerDistance(String a,String b){
        //if(a==b)return 1;
        Decimal p = 0.1;//scale netween 0.0 and 0.25
        Decimal jaroSim = calcJaroDistance(a,b);
        Decimal x = a.indexOfDifference(b);
        Decimal l = (x==-1?a.length():x);//index of first difference 
        l=Math.min(4, l);
        Decimal j =  jaroSim+p*l*(1-jaroSim);
        //system.debug('Matching '+a+' to '+b+' = '+j);
        return j;
    }
    public static Decimal calcJaroDistance(String a,String b){
        if(a==b)return 1;
        Decimal aLen = a.length();//length of a
        Decimal bLen = b.length();//length of b
        Decimal m = 0;// number of shared symbols
        Decimal t = 0;
        Integer maxDist = (Integer) (Math.floor(Math.max(aLen, bLen) / 2) - 1);
        List<Integer> aMatches = new List<Integer>();
        List<Integer> bMatches = new List<Integer>();
    
        for (Integer i = 0; i < aLen; i++) {
            Integer bMin = (Integer)Math.min(bLen, i + maxDist + 1);
            for (Integer j = Math.max(0, i - maxDist); j < bMin; j++){
                if (a.charAt(i) == b.charAt(j)){
                    aMatches.add(a.charAt(i));
                    bMatches.add(b.charAt(j));
                    m++;
                    break;
                }
            }
        }
        if(m==0||aLen==0||bLen==0)return 0;
        for (Integer i = 0; i < aMatches.size(); i++) {
            if(aMatches[i]!=bMatches[i]){
                t++;
            }
        }
        t /= 2;
        Decimal d = (m/aLen + m/bLen + (m-t)/m)/3;
        //system.debug('A='+aLen+' B='+bLen+' m='+m+' t='+t+' d='+d);
        return d;
    }
    
}
