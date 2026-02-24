public class ReplaceNewlinesWithHtmlTags {

    @InvocableMethod(label='Replace Newlines with HTML Tags')
    public static List<String> replaceNewlines(List<String> inputTextList) {
        List<String> outputTextList = new List<String>();
        for (String inputText : inputTextList) {
            String outputText = inputText.replace('\n', '<br/>');
            outputTextList.add(outputText);
        }
        return outputTextList;
    }
}