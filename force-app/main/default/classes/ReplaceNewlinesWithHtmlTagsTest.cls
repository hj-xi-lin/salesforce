@IsTest
public class ReplaceNewlinesWithHtmlTagsTest {

    @IsTest
    public static void testReplaceNewlinesWithHtmlTags() {
        // Test input and output data
        List<String> inputTextList = new List<String>{'This is a\nlong text field\nwith line breaks.'};
        List<String> expectedOutputTextList = new List<String>{'This is a<br/>long text field<br/>with line breaks.'};

        // Call the ReplaceNewlinesWithHtmlTags class to get the actual output
        List<String> actualOutputTextList = ReplaceNewlinesWithHtmlTags.replaceNewlines(inputTextList);

        // Compare the expected output with the actual output
        System.assertEquals(expectedOutputTextList, actualOutputTextList);
    }
}