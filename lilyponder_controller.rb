require 'fileutils'

TODO = <<-TXT
  - Save As...
  - Syntax Highlighting
TXT

class LilyponderController
  attr_accessor :pdf_view, :text_view, :regenerate_button
  attr_accessor :error_label, :progress_bar
  attr_accessor :destination_path, :regenerate_pdf
  
  LILYPOND_EXECUTABLE = "/Applications/Lilypond.app/Contents/Resources/bin/lilypond"
  SUPPORT_DIR = "~/Application Support/Lilyponder".stringByExpandingTildeInPath
  GENERIC_FILENAME = "#{SUPPORT_DIR}/temp"
  LY_FILENAME = GENERIC_FILENAME + ".ly"
  PDF_FILENAME = LY_FILENAME + ".pdf"
  
  def awakeFromNib
    @currentfile = LY_FILENAME
    set_up_filesystem
    clear_text_view!
    @text_view.setDelegate(self)
  end

  def clear_text_view!
    @text_view.setString("")
  end
  
  def new_document(sender)
    clear_text_view!
  end

  def open_document(sender)
    dialog = NSOpenPanel.openPanel
    dialog.canChooseFiles = true
    dialog.allowedFileTypes = ["ly"]
    if dialog.runModal == NSOKButton
      # if we had a allowed for the selection of  multiple items
      # we would have want to loop through the selection
      read_from_ly_file(dialog.filenames.first)
    end
  end
  
  def save_document_as(sender)
    dialog = NSSavePanel.new
    
    dialog.allowedFileTypes = ["ly"]
    
    if dialog.runModal == NSOKButton
      path = dialog.filename
      @currentfile = path
      write_to_ly_file
    end
  end
  
  def save_document(sender)
    write_to_ly_file
  end
  
  # Called when @text_view loses focus
  def textDidEndEditing(notification)
    regenerate_pdf(notification)
  end

  # Called when the "Regenerate PDF" button is pushed
  # or from textDidEndEditing above
  def regenerate_pdf(sender)
    write_to_ly_file
    run_lilypond_task(sender)
    reload_pdf
  end

  def reload_pdf
    data = NSData.dataWithContentsOfFile(@currentfile + ".pdf")
    document = PDFDocument.new.initWithData(data)
    @pdf_view.setDocument(document)
  end

  def run_lilypond_task(sender)
    task = NSTask.launchedTaskWithLaunchPath(LILYPOND_EXECUTABLE,
      arguments:["-o#{@currentfile}", @currentfile ])
    set_visibilities_during_lilypond_task(sender)
    task.waitUntilExit
    handle_results(task)
  end

  def set_visibilities_during_lilypond_task(sender)
    @pdf_view.setHidden(true)
    @error_label.setHidden(true)
    @progress_bar.setHidden(false)
    @progress_bar.startAnimation(sender)
  end

  def handle_results(task)
    @progress_bar.setHidden(true)
    case task.terminationStatus
    when 0
      @pdf_view.setHidden(false)
    when 1
      @error_label.setHidden(false)
    end
  end

  def read_from_ly_file(path)
    clear_text_view!
    file = File.open(path, "r")
    @text_view.insertText(file.readlines.join(""))
    file.close
    @currentfile = path
    reload_pdf
  end

  def write_to_ly_file
    clean_text_view_string
    File.open(@currentfile, "w") do |file|
      file << @text_view.string
    end
  end

  def clean_text_view_string
    @text_view.insertText(" ") if @text_view.string == ""
  end

  def set_up_filesystem
    FileUtils.mkdir_p(SUPPORT_DIR) unless File.exists?(SUPPORT_DIR)
    FileUtils.touch(@currentfile)
  end

end
