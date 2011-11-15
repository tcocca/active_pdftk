require 'spec_helper'

inputs = [:path, :hash, :file, :tempfile, :stringio]
outputs = [:path, :file, :tempfile, :stringio, :nil]

def get_input(input_type, file_name = 'spec.fields.pdf')
  case input_type
  when :path
    path_to_pdf(file_name)
  when :hash
    {path_to_pdf(file_name) => nil}
  when :file
    File.new(path_to_pdf(file_name))
  when :tempfile
    t = Tempfile.new('input.spec')
    t.write(File.read(path_to_pdf(file_name)))
    t
  when :stringio
    StringIO.new(File.read(path_to_pdf(file_name)))
  end
end

def get_output(output_type)
  case output_type
  when :path
    path_to_pdf('output.spec')
  when :file
    File.new(path_to_pdf('output.spec'), 'w+')
  when :tempfile
    Tempfile.new('output.spec')
  when :stringio
    StringIO.new()
  when :nil
    nil
  end
end

def map_output_type(output_specified)
  case output_specified
  when :path
    String
  when :file
    File
  when :tempfile
    Tempfile
  when :stringio, :nil
    StringIO
  end
end

def cleanup_file_content(text)
  text.force_encoding('ASCII-8BIT') if text.respond_to? :force_encoding   # PDF embed some binary data breaking gsub with ruby 1.9.2
  text.gsub!(/\(D\:.*\)/, '')                                             # Remove dates ex: /CreationDate (D:20111106104455-05'00')
  text.gsub!(/\/ID \[<\w*><\w*>\]/, '')                                   # Remove ID values ex: /ID [<4ba02a4cf55b1fc842299e6f01eb838e><33bec7dc37839cadf7ab76f3be4d4306>]
  text
end

describe ActivePdftk::Wrapper do
  before(:all) { @pdftk = ActivePdftk::Wrapper.new }

  context "new" do
    it "should instantiate the object." do
      @pdftk.should be_an_instance_of(ActivePdftk::Wrapper)
    end

    it "should pass the defaults statements to the call instance." do
      path = ActivePdftk::Call.new.locate_pdftk
      @pdftk_opt = ActivePdftk::Wrapper.new(:path => path, :operation => {:fill_form => 'a.fdf'}, :options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'})
      @pdftk_opt.default_statements.should == {:path => path, :operation => {:fill_form => 'a.fdf'}, :options => { :flatten => false, :owner_pw => 'bar', :user_pw => 'baz', :encrypt  => :'40bit'}}
    end
  end

  shared_examples "a working command" do
    it "should return a #{@output.nil? ? StringIO : @output.class}" do
      @call_output.should be_kind_of(@output.nil? ? StringIO : @output.class)
    end

    it "should return expected data" do
      open_or_rewind(@call_output).should == @example_expect
    end

    after(:each) { remove_output(@call_output) }
  end

  shared_examples "a combination command" do
    it "should return a #{@output.nil? ? StringIO : @output.class}" do
      @call_output.should be_kind_of(@output.nil? ? StringIO : @output.class)
    end

    it "should return expected data" do
      cleanup_file_content(@example_expect)
      text = open_or_rewind(@call_output)
      cleanup_file_content(text)
      text.should == @example_expect
    end

    after(:each) { remove_output(@call_output) }
  end

  inputs.each do |input_type|
    outputs.each do |output_type|

      context "(Input:#{input_type}|Output:#{output_type})" do
        before :each do
          @input = get_input(input_type)
          @input.rewind rescue nil # rewind if possible.
          @output = get_output(output_type)
        end

        describe "#dump_data_fields" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('dump_data_fields/expect.data_fields')).read }
            before(:each) { @call_output = @pdftk.dump_data_fields(@input, :output => @output) }
          end
        end

        describe "#fill_form" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fill_form/expect.pdf')).read }
            before(:each) { @call_output = @pdftk.fill_form(@input, path_to_pdf('fill_form/spec.fdf'), :output => @output) }
          end
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fill_form/expect.pdf')).read }
            before(:each) { @call_output = @pdftk.fill_form(@input, path_to_pdf('fill_form/spec.xfdf'), :output => @output) }
          end
        end

        describe "#generate_fdf" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('generate_fdf/expect.fdf')).read }
            before(:each) { @call_output = @pdftk.generate_fdf(@input,:output => @output) }
          end
        end

        describe "#dump_data" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('dump_data/expect.data')).read }
            before(:each) { @call_output = @pdftk.dump_data(@input,:output => @output) }
          end
        end

        describe "#update_info" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('update_info/expect.pdf')).read }
            before(:each) { @call_output = @pdftk.update_info(@input, path_to_pdf('update_info/spec.data'), :output => @output) }
          end
        end

        describe "#unpack_files" do
          before(:all) { @example_expect = open_or_rewind(path_to_pdf('unpack_files/expect.txt')) }

          context "to path", :if => output_type == :path do
            before(:each) do
              @input = get_input(input_type, 'unpack_files/spec.pdf')
              @input.rewind rescue nil # rewind if possible.
              @call_output = @pdftk.unpack_files(@input, path_to_pdf('unpack_files'))
            end

            it "should unpack the files" do
              @call_output.should == path_to_pdf('unpack_files')
              open_or_rewind(path_to_pdf('unpack_files/unpacked_file.txt')).should == @example_expect
              File.unlink(path_to_pdf('unpack_files/unpacked_file.txt')).should == 1
            end
          end

          context "to temporary directory", :if => output_type == :nil do
            before(:each) do
              @input = get_input(input_type, 'unpack_files/spec.pdf')
              @input.rewind rescue nil # rewind if possible.
              @call_output = @pdftk.unpack_files(@input, nil)
            end

            it "should unpack the files" do
              @call_output.should == Dir.tmpdir
              open_or_rewind(File.join(Dir.tmpdir, 'unpacked_file.txt')).should == @example_expect
              File.unlink(File.join(Dir.tmpdir, 'unpacked_file.txt')).should == 1
            end
          end
        end

        describe "#attach_files", :focus => true do
          before(:each) do
            @call_output = @pdftk.attach_files(@input,  fixtures_path('attach_files/expect', true).collect(&:to_s), :output => @output)
          end

          it "should bind the file in the pdf" do
            Dir.mktmpdir do |directory|
              @pdftk.unpack_files(@call_output, directory)
              Pathname.new(directory).should have_the_content_of(fixtures_path('attach_files/expect'))
            end
          end

          it "should output the correct type" do
            @call_output.should be_kind_of(map_output_type(output_type))
          end
        end

        describe "#background" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('background/expect.pdf')).read }
            before(:each) { @call_output = @pdftk.background(@input, path_to_pdf('spec.a.pdf'), :output => @output) }
          end

          pending "spec multibackground also"
        end

        describe "#stamp" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('stamp/expect.pdf')).read }
            before(:each) { @call_output = @pdftk.stamp(@input, path_to_pdf('spec.a.pdf'), :output => @output) }
          end

          pending "check if the output is really a stamp & spec multistamp also"
        end

        describe "#cat" do
          it_behaves_like "a combination command" do
            before(:all) { @example_expect = File.new(path_to_pdf('cat/expect.pdf')).read }
            before(:each) { @call_output = @pdftk.cat([{:pdf => path_to_pdf('spec.a.pdf')}, {:pdf => path_to_pdf('spec.b.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => @output) }
          end
        end

        describe "#shuffle" do
          it_behaves_like "a combination command" do
            before(:all) { @example_expect = File.new(path_to_pdf('shuffle/expect.pdf')).read }
            before(:each) { @call_output = @pdftk.shuffle([{:pdf => path_to_pdf('spec.a.pdf')}, {:pdf => path_to_pdf('spec.b.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => @output) }
          end
        end

        describe "#burst" do
          context 'to path', :if => output_type == :path do
            before(:each) do
              @input = get_input(input_type, 'spec.a.pdf')
              @input.rewind rescue nil # rewind if possible.
            end

            it "should file into single pages" do
              output = path_to_pdf('burst/pg_%04d.pdf')
              @pdftk.burst(@input, :output => output).should == output
              File.unlink(path_to_pdf('burst/pg_0001.pdf')).should == 1
              File.unlink(path_to_pdf('burst/pg_0002.pdf')).should == 1
              File.unlink(path_to_pdf('burst/pg_0003.pdf')).should == 1
            end
          end

          context "#to temporary directory", :if => output_type == :nil do
            before(:each) do
              @input = get_input(input_type, 'spec.a.pdf')
              @input.rewind rescue nil # rewind if possible.
            end

            it "should file into single pages" do
              @pdftk.burst(@input, :output => nil).should == Dir.tmpdir
              File.unlink(File.join(Dir.tmpdir, 'pg_0001.pdf')).should == 1
              File.unlink(File.join(Dir.tmpdir, 'pg_0002.pdf')).should == 1
              File.unlink(File.join(Dir.tmpdir, 'pg_0003.pdf')).should == 1
            end

            it "should put a file in the system tmpdir when no output location given but a page name format given" do
              @pdftk.burst(@input, :output => 'page_%02d.pdf').should == 'page_%02d.pdf'
              File.unlink(File.join(Dir.tmpdir, 'page_01.pdf')).should == 1
              File.unlink(File.join(Dir.tmpdir, 'page_02.pdf')).should == 1
              File.unlink(File.join(Dir.tmpdir, 'page_03.pdf')).should == 1
            end
          end
        end
      end

    end # each outputs
  end # each inputs

  context "burst" do
    it "should call #pdtk on @call" do
      @pdftk.call.should_receive(:pdftk).with({:input => path_to_pdf('spec.fields.pdf'), :operation => :burst})
      @pdftk.burst(path_to_pdf('spec.fields.pdf'))
      @pdftk.call.should_receive(:pdftk).with({:input => path_to_pdf('spec.fields.pdf'), :operation => :burst, :options => {:encrypt  => :'40bit'}})
      @pdftk.burst(path_to_pdf('spec.fields.pdf'), :options => {:encrypt  => :'40bit'})
    end
  end

  context "cat" do
    it "should call #pdftk on @call" do
      @pdftk.call.should_receive(:pdftk).with({:input => {'a.pdf' => 'foo', 'b.pdf' => nil}, :operation => {:cat => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]}})
      @pdftk.cat([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}])
    end
  end

  context "shuffle" do
    it "should call #pdftk on @call" do
      @pdftk.call.should_receive(:pdftk).with({:input => {'a.pdf' => 'foo', 'b.pdf' => nil}, :operation => {:shuffle => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]}})
      @pdftk.shuffle([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}])
    end
  end

end # Wrapper
