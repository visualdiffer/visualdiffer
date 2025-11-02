#!/usr/bin/env ruby

require 'FileUtils'


folderReaderStr = '
        let comparatorDelegate = MockFolderStatusComparatorDelegate()
        let comparator = FolderStatusComparator(
                                                delegate: comparatorDelegate,
                                                bufferSize: 8192,
                                                )
        let filterConfig = FilterConfig(
        showFilteredFiles: ,
                                        hideEmptyFolders: ,
                                        followSymLinks: ,
                                        skipPackages: ,
                                        traverseFilteredFolders: false,
                                        predicate: defaultPredicate,
                                        fileInfoOptions: 0,
                                        displayOptions: .showAll)
        let folderReaderDelegate = MockFolderReaderDelegate(isRunning: true)
        let folderReader = FolderReader(with: folderReaderDelegate,
                                        comparator: comparator,
                                        filterConfig: filterConfig,
                                        refreshInfo: RefreshInfo(initState: true))
'

# Array di coppie [regex, replacement] da applicare
regexps_tests = [
  [/\[self addTags:@?(.*?) fullPath:(.*?)\];/, 'add(tags: \1, fullPath:\2)'],
  [/:(VDComparatorType.*)/, Proc.new { |m| "flags: [#{m[0].gsub('|', ', ')}]," }],
  [/^.*comparator\.(.*CaseSensitive)\s*=\s*(.*?);/, Proc.new { |m| renamedToIS(m, 0, 'is\1: \2,') }],
  [/folderReader\.(.*?)\s*=\s*(.*?);/, '\1: \2,'],
  [/[;@]/, ''],
  [/^{$/, ''], # remove { only for function definition with { on newline as unique character
  [/(\d+)L/, '\1'],
  [/(.):([^\s.])/, '\1: \2'],
  # [/- \(void\)(test[^(\s{)]*)/, '@Test func \1() throws '],
  [/-\s*\(void\)test([^(\s{)]*)/, Proc.new { |m| downcaseFirstLetter(m, 0, '@Test func \1() throws {') }],
  [/^\s+FolderStatus\* rootL, \*rootR\n/, ''],
  [/^\s+NSError\* error = nil\n/, ''],
  [/^\s+VisibleItem\* vi\n/, ''],
  [/rootL = folderReader.leftRoot/, 'let rootL = folderReader.leftRoot!'],
  [/rootR = folderReader.rightRoot/, '// let rootR = folderReader.rightRoot!'],
  [/vi = rootL.visibleItem/, 'let vi = rootL.visibleItem!'],

  [/VDMockFolderReaderDelegate\* delegate = \[\[VDMockFolderReaderDelegate alloc\] initWithRunningState:\s*(.*)\]/, ''],

  [/(FolderStatus\*|VisibleItem\*)/, 'let'],
  [/StatusAssert/, 'assertStatus'],
  [/\[(.*)\.subfolders objectAtIndex:\s*(\d+)\]/, '\1.subfolders[\2]'],

  [/^(\s+)\{/, '\1do {'],
  [/ArrayCountAssert/, 'assertArrayCount'],
  [/\[(childVI\d+) item\]/i, '\1.item'],
  [/\bYES\b/, 'true'],
  [/\bNO\b/, 'false'],
  [/\bCreateFolder\b/, 'try createFolder'],
  [/\bCreateFile\b/, 'try createFile'],
  [/\bCreateDataFile\b/, 'try createDataFile'],
  [/\bSetFileTimestamp\b/, 'try setFileTimestamp'],
  [/\bSetFileTimestamp\b/, 'try setFileTimestamp'],
  [/\bSetFileCreationTime\b/, 'try setFileCreationTime'],
  [/\bCreateSymlink\b/, ' try createSymlink'],
  [/\bAppendFolder\b/, ' appendFolder'],
  [/\bStatusFolderLabels\b/, 'assertFolderLabels'],
  [/\bStatusMismatchingLabels\b/, 'assertMismatchingLabels'],
  [/\bStatusFolderTags\b/, 'assertFolderTags'],
  [/\bStatusMismatchingTags\b/, 'assertMismatchingTags'],
  [/ResourceFileLabels/, 'assertResourceFileLabels'],
  [/\[self add(.*?Number):(.*) fullPath:(.*?)\]/, Proc.new { |m| downcaseFirstLetter(m, 0, 'try add(\1: \2, fullPath:\3)') }],
  [/let operationElement/, 'var operationElement: FolderStatus'],

  [/\[fm removeItemAtPath:\s*appendFolder\(@?(.*?)\) error:.*\]/, 'try removeItem(\1)'],

  [/\bXCTAssertTrue\b/, '#expect'],
  [/\bSymlinkAssert\b/, 'try assertSymlink'],
  [/\bTimestampsAssert\b/, 'try assertTimestamps'],
  [/VDMakeRefreshInfo\((.*?)\)/, 'RefreshInfo(initState: \1)'],
  [/VDFolderReader\* folderReader = \[\[VDFolderReader alloc\] initWithDelegate:\s*delegate\]/, folderReaderStr],
  [/folderReader.comparator = \[FolderStatusComparator comparatorWithFlags/, "let comparator = FolderStatusComparator(\nflags "],
  [/FolderStatusComparator\* comparator = \[FolderStatusComparator comparatorWithFlags/, "let comparator = FolderStatusComparator(\nflags"],
  [/displayFilters: (.*?),/, 'displayOptions: \1)'],
  [/.*VDComparatorType\)\(([^)]+)\)/, Proc.new { |m| "flags: [#{m[0].gsub('|', ', ')}]," }],
  [/^(\s+)rightRoot: nil$/, '\1rightRoot: nil,'],
  [/^(\s+)leftPath:\s*(appendFolder.*)/, '\1leftPath: \2,'],
  [/^(\s+)rightPath:\s*(appendFolder.*?)\]/, '\1rightPath: \2)'],
  [/bufferSize:\s*(\d+)\]/, 'bufferSize: \1,' "\n)"],
  [/linkedItem\./, 'linkedItem!.'],

  [/%ld found %ld", (.*?), (.*?)\)/, '\\(\1) found \\(\2)")'],
  [/\[folderReader readFoldersWithLeftRoot:\s*nil/, 'folderReader.start(withLeftRoot: nil,'],
  # [ /(?:.*) (.*) = (.*)/, 'let \1 = \2'],
  [/MockFileOperationDelegate\* mockDelegate = \[\[MockFileOperationDelegate alloc\] initWithReplaceFlag:\s*(.*)\];?/, 'let fileOperationDelegate = MockFileOperationManagerDelegate(replaceAll: \1)'],
  [/StatusMismatchingTags/, 'assertUtils.mismatchingTags'],
  [/StatusFolderTags/, 'assertUtils.folderTags'],

  [/VD_ASSERT_ONLY_SETUP/, '// VD_ASSERT_ONLY_SETUP'],
  [/MockFolderManagerDelegate\* mockDelegate/, ' let mockDelegate'],
  [/VDLocalFileManager\* fsu = \[VDLocalFileManager localWithIncludesFiltered: includesFiltered/,
   "
        let fileOperationManager = FileOperationManager(filterConfig: filterConfig,
                                                        comparator: comparator,
                                                        delegate: fileOperationDelegate)
        let fileOperation = DeleteFolderStatus(operationManager: fileOperationManager)
        let fileOperation = CopyFolderStatus(operationManager: fileOperationManager,
                                             bigFileSizeThreshold: 100_000)
        let fileOperation = MoveFolderStatus(operationManager: fileOperationManager,
                                             bigFileSizeThreshold: 100_000)
        let fileOperation = RenameFolderStatus(operationManager: fileOperationManager)
        let fileOperation = TouchFolderStatus(operationManager: fileOperationManager)

"],
  

  [/\[fsu (.*)FolderStatus:\s*(.*)/, 'fileOperation.\1(\2,'],
  [/BOOL includesFiltered = (.*)/, 'let includesFiltered = \1'],

  [/\[(.*) (add.*):\s*(.*)\]/, '\1.\2(\3)'],
  [/NSString\*/, 'String'],
  [/NSDictionary\*/, '[DKey: DValue]'],
  [/NSArray\*/, '[ArrType]'],
  [/VDFileManager\*/, 'FileManager'],
  [/BOOL/, 'Bool'],
  [/FSFileCountHolder\*?/, 'FileCountHolder'],
  [/MockFileOperationDelegate/, 'MockFolderManagerDelegate'],
  [/FSFileCountHolderInit/, 'FileCountHolder'],
  [/#pragma mark/, '// MARK:'],

  [/\bVDComparisonStatus([a-zA-Z]+?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],
  [/\bVDComparatorType([a-zA-Z]+?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],
  [/\bVDDisplayFilter([a-zA-Z]+?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],

  # [/(?:VDComparisonStatus|VDDisplayFilter|VDComparatorType)([a-zA-Z]*)/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],

]

regexps_methods = [
  [ /^-\s*\(IBAction\)(.*):\s*\(id\)\s*sender\s*{/, '@objc func \1(_ sender: AnyObject) {'],

  # method declared on single line
  # [ /- \((.*?)\)(.*?):\((.*)\)(.*);/, 'func \2(\4: \3) -> \1'],

  # function no arguments
  [ /-\s*\(void\)\s*(.*?)\s*{/, 'func \1() {'],
  [ /-\s*\(([a-zA-Z]+)\s*\*?\)\s*([a-zA-Z]+)\s*{/, 'func \2() -> \1 {'],

  # static getter
  [/^\+\s*\(([a-zA-Z]*) \*\)\s*([a-zA-Z]*)\s*{/, 'static func \2() -> \1 {'],
  # static setter
  # [/^\+\s*\(([a-zA-Z]*)\)\s*([a-zA-Z]*)\s*:\((.*?)\)(.*?)\s*{/, 'static func \2(_ \4: \3) {'],

  # function declaration 3 arguments single line (group are more than 9 and ruby can't recognize \10 so we use named groups)
  [/^-\s*\(void\)((?<fname>.*?)):\(((?<t1>.*?))\)((?<p1>.*?))\s+.*?:\(((?<t2>.*?))\)((?<p2>.*?)) .*?:\(((?<t3>.*?))\)((?<p3>.*?)) {/,
   'func \k<fname>(_ \k<p1>: \k<t1>, \k<p2>: \k<t2>, \k<p3>: \k<t3>) {'],

  [/^-\s*\((?<rtype>(.*?))\)((?<fname>.*?)):\(((?<t1>.*?))\)((?<p1>.*?))\s+.*?:\(((?<t2>.*?))\)((?<p2>.*?)) .*?:\(((?<t3>.*?))\)((?<p3>.*?)) {/,
   'func \k<fname>(_ \k<p1>: \k<t1>, \k<p2>: \k<t2>, \k<p3>: \k<t3>) -> \k<rtype> {'],

  # static function declaration 3 arguments single line
  [/^\+\s*\((?<rtype>(.*?))\)((?<fname>.*?)):\(((?<t1>.*?))\)((?<p1>.*?))\s+.*?:\(((?<t2>.*?))\)((?<p2>.*?)) .*?:\(((?<t3>.*?))\)((?<p3>.*?)) {/,
   'static func \k<fname>(_ \k<p1>: \k<t1>, \k<p2>: \k<t2>, \k<p3>: \k<t3>) -> \k<rtype> {'],

  # function declaration 2 argument single line
  [/^-\s*\((void)\)(.*?):\((.*?)\)(.*?)\s+.*?:\((.*?)\)(.*?)(.*?) {/, 'func \2(_ \4: \3, \7: \5) {'],
  [/^-\s*\((.*?)\)(.*?):\((.*?)\)(.*?)\s+.*?:\((.*?)\)(.*?)(.*?) {/, 'func \2(_ \4: \3, \7: \5) -> \1 {'],

  # static function declaration 2 argument single line
  [/^\+\s*\((void)\)(.*?):\((.*?)\)(.*?)\s+.*?:\((.*?)\)(.*?)(.*?) {/, 'static func \2(_ \4: \3, \7: \5) {'],
  [/^\+\s*\((.*?)\)(.*?):\((.*?)\)(.*?)\s+.*?:\((.*?)\)(.*?)(.*?) {/, 'static func \2(_ \4: \3, \7: \5) -> \1 {'],

  # function declaration convert only first line
  [/^-\s*\(([a-zA-Z]+)\s*\*?\)([a-zA-Z]+):\(([a-zA-Z]+)\s*\*?\)([a-zA-Z]+)\s*{$/, 'func \2(_ \4: \3) -> \1 {'],
  [/^\+\s*\(([a-zA-Z]+)\s*\*?\)([a-zA-Z]+):\(([a-zA-Z]+)\s*\*?\)([a-zA-Z]+)\s*{$/, 'static func \2(_ \4: \3) -> \1 {'],

  # function call 3 parameters
  [/\[(self)\s+([a-zA-Z]+):([a-zA-Z\._]+)\s+([a-zA-Z]+):([a-zA-Z\._]+)\s+([a-zA-Z]+):([a-zA-Z\._]+)\]/, '\2(\3, \4: \5, \6: \7)'],
  [/\[([a-zA-Z]+)\s+([a-zA-Z]+):([a-zA-Z\._]+)\s+([a-zA-Z]+):([a-zA-Z\._]+)\s+([a-zA-Z]+):([a-zA-Z\._]+)\]/, '\1.\2(\3, \4: \5, \6: \7)'],

  # function call 2 parameters
  [/\[(self)\s+([a-zA-Z]+):([a-zA-Z\._]+)\s+([a-zA-Z]+):([a-zA-Z\._]+)\]/, '\2(\3, \4: \5)'],
  [/\[([a-zA-Z]+)\s+([a-zA-Z_]+):([a-zA-Z\._]+)\s+([a-zA-Z]+):([a-zA-Z\._]+)\]/, '\1.\2(\3, \4: \5)'],

  # convert property
  # [/@property\s+\((.*?)\)\s+(.*?)\*?\s+(.*?);/, 'var \3: \2 // dafi: \1'],

  # private variable declaration
  [/    (.*)\* ([a-zA-Z]*);/, '    private var \2: \1'],

  # variable assignment (remove type)
  [/(^\s+)[a-zA-Z\*]+ ([a-zA-Z]+?) =\s+/, '\1let \2 = '],

  # # method declared on multiple lines
  # [ /- \((.*?)\)(.*):\((.*)\)(.*)/, 'func \2(\4: \3) // -> \1'],
  # [/^\s(.*?):\((.*)\)(.*)/, '\1 \3: \2,'],

  [ /^\s+([a-zA-Z]+):\(([a-zA-Z\*]+)\)([a-zA-Z]+)$/, Proc.new { |m| remove_identical_argument_name(m, ",") }],
  [ /^\s+([a-zA-Z]+):\(([a-zA-Z\*]+)\)([a-zA-Z]+) {$/, Proc.new { |m| remove_identical_argument_name(m,  ") {") }],

  [ /@interface (.*)\(\) {/, 'class \1 {'],
  [ /@implementation (.*)$/, 'class \1 {'],

  [ /@selector\(([a-zA-Z]*):\)/, '#selector(\1)'],

  [ /for \([a-zA-Z]*\* ([a-zA-Z]*) in (.*)\) {/, 'for \1 in \2 {'],

  [/NSFileManager\.defaultManager\(\)/, 'FileManager.default'],
  [/\[NSFileManager defaultManager\]/, 'FileManager.default'],

  [/[;]/, ''],
  # [/@"/, '"'],

  [/\[(.*)\.subfolders objectAtIndex:\s*(\d+)\]/, '\1.subfolders[\2]'],

  # [ /(?:VDComparisonStatus|VDDisplayFilter|VDComparatorType)([a-zA-Z]*)/, Proc.new { |m| create_optionset(m) }],
  
  # optionset
  [ /(?:NSButtonType|NSControlStateValue|NSBezelStyle|NSTextAlignment|NSUserInterfaceLayoutOrientation|NSLayoutAttribute|NSLineBreak|NSImageScale)([a-zA-Z]*)/,
   Proc.new { |m| downcaseFirstLetter(m, 0) }],
  [/(?:NSWindowStyleMask|NSBackingStore|NSTitlebarSeparatorStyle|NSControlSize)([a-zA-Z]+)/, Proc.new { |m| downcaseFirstLetter(m, 0) }],
  [/(?:NSDragOperation|NSEventModifierFlag)([a-zA-Z]+)/, Proc.new { |m| downcaseFirstLetter(m, 0) }],

  [/\bYES\b/, 'true'],
  [/\bNO\b/, 'false'],

  [/VDMakeRefreshInfo\((.*?)\)/, 'RefreshInfo(initState: \1)'],
  [/FolderStatusComparator\* comparator = \[FolderStatusComparator comparatorWithFlags/, 'let comparator = FolderStatusComparator(flags:'],
  [/displayFilters:/, 'displayFlags:'],
  [/bufferSize:\s*(\d+)\]/, 'bufferSize: \1)'],

  # [/\[folderReader readFoldersWithLeftRoot:\s*nil/, 'folderReader.readFolders(withLeftRoot: nil,'],

  [/addItemWithTitle:(.*)/, 'addItem(withTitle: \1'],
  [/\[(.*) (add.*):\s*(.*)\]/, '\1.\2(\3)'],
  # [/FSFileCountHolderAdd\((.*), \&(.*)\);?/, '\1 += \2'],
  # [/FSFileCountHolderSub\((.*), \&(.*)\);?/, '\1 -= \2'],

  [/initWithFrame:\(NSRect\)frame/, 'init(frame frameRect: NSRect)'],
  [/self = \[super initWithFrame:frameRect\]/, 'super.init(frame: frameRect)'],
  [/self = \[super initWithFrame:frame\]/, 'super.init(frame: frameRect)'],
  # convert [[xxx alloc ] initWithFrame]
  [/\[\[(.*?) alloc\] initWithFrame:(.*?)\];/, '\1(frame: \2)'],
  # convert [[xxx alloc ] init]
  [/\[\[([a-zA-Z]+) alloc\] init(.*?):(.*?)\]/, '\1(\2: \3)'],
  [/\[\[([a-zA-Z]+) alloc\] init\]/, '\1()'],

  [/if \(self\) \{/, '{'],

  # [/\[(.*Anchor) (constraint)(.*)\]/, '\1.\2(\3)'],
  [/\[(.*Anchor) (constraint)(.*)\]/, Proc.new { |m| downcaseFirstLetter(m, 2, '\1.\2(\3)') }],
  [ /Anchor constant/, 'Anchor, constant'],

  [/\.(restorable|bordered|bezeled|editable|selectable|buttonBordered|hidden|enabled)/, Proc.new { |m| renamedToIS(m, 0) }],
  [/\(With(Frame|Title|Identifier):/, Proc.new { |m| downcaseFirstLetter(m, 0, '(\1:') }],
  [/\bVDDisplayPosition(Left|Right)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],
  [/\bVDSelectionType(.*?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],
  [/\bVDComparisonStatus([a-zA-Z]+?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],
  [/\[NSLayoutConstraint activateConstraints:/, 'NSLayoutConstraint.activate('],
  [/equalToAnchor/, 'equalTo'],

  [/\.buttonType = (.*)/, '.setButtonType(\1)'],

  [/\bNSString\b/, 'String'],
  [/(NSImage|NSButton|FolderStatus|NSTableView|NSEvent)\s*\*/, '\1 '],
  # [ /NSDictionary\*/, '[DKey: DValue]'],
  [/NSArray\*/, '[ArrType]'],
  [/NSNotification/, 'Notification'],
  [/\bNSURL\b/, 'URL'],
  [/\bNSInteger\b/, 'Int'],
  [/\bNSUInteger\b/, 'UInt'],
  [/\bNSImageOnly\b/, '.imageOnly'],
  [/\bseparatorItem\b/, 'separator'],
  [/\bNSTableColumnAutoresizingMask\b/, '.autoresizingMask'],
  [/\bNSTableColumnUserResizingMask\b/, '.userResizingMask'],

  [/\bdefaultCenter\b/, 'default'],
  [/NSUserDefaults(.)standardUserDefaults/, 'UserDefaults\1standard'],
  [/VDFileManager\*/, 'FileManager'],
  [/BOOL/, 'Bool'],
  [/\bis(Folder|File)Object\b/, 'is\1'],
  [/FSFileCountHolder\*?/, 'FileCountHolder'],
  [/sharedDocumentController/, 'shared'],
  [/#pragma mark/, '// MARK: -'],

  [/\[(.*) isEqualToString:(.*?)\]/, '\1 == \2'],
  [/NSMakeRect\((.+?), (.+?), (.+?), (.+?)\)/, 'NSRect(x: \1, y: \2, width: \3, height: \4)'],
  [/\bNSZeroRect\b/, '.zero'],
  [/NSMakeSize\((.*?), (.*?)\)/, 'NSSize(width: \1, height: \2)'],
  [/NSMakeRange\((.+?), (.+?)\)/, 'NSRange(location: \1, length: \2)'],

  [/NSLocalizedString\((.*?), nil\)/, 'NSLocalizedString(\1, comment: "")'],

  # font
  [/\[NSFont (.*)OfSize:(NSFont..*)\]/, 'NSFont.\1(ofSize: \2)'],

  # self is removed
  [/\[self ([a-zA-Z]*?)\]/, '\1()'],
  [/\[([a-zA-Z\.]*?) ([a-zA-Z]*?)\]/, '\1.\2()'],

  [/frameAutosaveName = "(.*?)"/, 'setFrameAutosaveName("\1")'],

  [ /\[NSImage imageNamed:(.*?)\]/, 'NSImage(named: \1)'],
  [ /- \(instancetype\)/, ''],

  [/\bif\b\s*\((.*?)\)/, 'if \1'],
  [/\bid\b/, 'Any'],

  # for menu definition
  [/ action:(.*) keyEquivalent\(/, ', action:\1, keyEquivalent:'],
  [/\[NSMenuItem\.alloc\(\) initWithTitle/, 'NSMenuItem(title'],
  [/keyEquivalent:"(.*)"\]/, 'keyEquivalent:"\1")'],
  [/\[([a-zA-Z]*) setAlternate:(.*)\]/, '\1.isAlternate = \2'],
  [/\[([a-zA-Z]*) setKeyEquivalentModifierMask:\((.*)\)\]/, '\1.keyEquivalentModifierMask = [\2]'],

  [/\bVDComparisonStatus([a-zA-Z]+?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],
  [/\bVDComparatorType([a-zA-Z]+?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],
  [/\bVDDisplayFilter([a-zA-Z]+?)\b/, Proc.new { |m| downcaseFirstLetter(m, 0, '.\1') }],

]

def renamedToIS(m, index, format_string)
  if m.empty?
    ""
  else
    upper = m[index][0].upcase + m[index][1..]
    if format_string
      duplicated = m.dup
      duplicated[index] = upper
      replaced = format_string
      duplicated.each_with_index { |el, i| replaced.gsub!("\\#{i + 1}", el) }
      replaced
    else
      ".is#{upper}"
    end
  end
end

def downcaseFirstLetter(m, index, format_string = nil)
  # puts "running on #{m} index #{index} format #{format_string}"
  if m.empty?
    ""
  else
    dc = m[index][0].downcase + m[index][1..]
    if format_string
      duplicated = m.dup
      duplicated[index] = dc
      replaced = format_string
      duplicated.each_with_index { |el, i| replaced.gsub!("\\#{i + 1}", el) }
      replaced
    else
      '.' + dc
    end
  end
end

def remove_identical_argument_name(m, separator)
  if m.empty?
    ""
  else
    if m[0] == m[2]
      "#{m[0]}: #{m[1]}#{separator}"
    else
      "#{m[0]} #{m[2]}: #{m[1]}#{separator}"
    end
  end
end

# Funzione per applicare tutte le regex e le sostituzioni a una riga
def apply_regexps(line, regexps)
  regexps.each do |regexp, replacement|
    do_replace(line, regexp, replacement)
  end
  line
end

def do_replace(line, regexp, replacement)
  if replacement.is_a?(String)
    # puts "line #{line} replacement #{replacement}"
    line.gsub!(regexp, replacement)
  elsif replacement.respond_to?(:call)
    line.gsub!(regexp) do |m|
      replacement.call(Regexp.last_match.captures)
    end
  end
end


  

# line = '[self addTags:@[@"Red"] fullPath:AppendFolder(@"l/Parent/FolderWithTags")];'
# # repl = [/\[self addTags:(\[.*\]) fullPath:(.*?)\]/, 'add(tags: \1, fullPath:\2)']
# repl = [/\[self addTags:@?(.*?) fullPath:AppendFolder((.*?))];/, 'add(tags: \1, fullPath:\2)']

# do_replace(line, repl[0], repl[1])

# puts "line is: #{line}"

# exit


# Controlla se è stato passato un file di input
if ARGV.empty?
  puts "Per favore, fornisci il nome di un file."
  exit 1
end

# Apri il file di ingresso
filename = ARGV[0]
reexp_used = if ARGV[1] == 'tests'
               STDERR.puts "Using tests regexp"
               regexps_tests
             else
               STDERR.puts "Using appl regexp"
               regexps_methods
             end

outdir = 'converted'
FileUtils.mkdir outdir unless File.exist?(outdir)
outname = File.join(outdir, "./#{File.basename(filename, ".*")}.conv")

begin
  File.open(outname, 'w') do |out|
    File.open(filename, 'r') do |file|
      file.each_line do |line|
        # Applica le espressioni regolari e le sostituzioni a ogni riga
        modified_line = apply_regexps(line, reexp_used)
        # Scrive la riga modificata su stdout
        out.print modified_line
      end
    end
  end
  system("subl #{outname}")
rescue Errno::ENOENT
  puts "Errore: Il file #{filename} non esiste."
  exit 1
end
