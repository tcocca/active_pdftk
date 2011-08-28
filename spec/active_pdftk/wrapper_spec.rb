require 'spec_helper'

inputs = [:path, :hash, :file, :tempfile, :stringio]
outputs = [:path, :file, :tempfile, :stringio, :nil]

def get_input(input_type, file_name = nil)
  case input_type
  when :path
    path_to_pdf(file_name || 'fields.pdf')
  when :hash
    {path_to_pdf(file_name || 'fields.pdf') => nil}
  when :file
    File.new(path_to_pdf(file_name || 'fields.pdf'))
  when :tempfile
    t = Tempfile.new('specs')
    t.write(File.read(path_to_pdf(file_name || 'fields.pdf')))
    t
  when :stringio
    StringIO.new(File.read(path_to_pdf(file_name || 'fields.pdf')))
  end
end

def get_output(output_type)
  case output_type
  when :path
    path_to_pdf('output.spec')
  when :file
    File.new(path_to_pdf('output.spec'), 'w+')
  when :tempfile
    Tempfile.new('specs2')
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
      case @call_output
        when String then File.new(@call_output).read.should == @example_expect
        else
          @call_output.rewind
          @call_output.read.should == @example_expect
      end
    end

    after(:all) do
      case @call_output
        when String then File.unlink(@call_output)
        when File then File.unlink(@call_output.path)
      end
    end
  end

  inputs.each do |input_type|
    outputs.each do |output_type|
      context "(Input:#{input_type}|Output:#{output_type})" do
        before(:all) { @input, @output = get_input(input_type), get_output(output_type) }
        after(:each) { @input.rewind rescue nil }

        describe "#dump_data_fields" do
          it_behaves_like "a working command" do
            before(:all) do
              @example_expect = File.new(path_to_pdf('fields.data_fields')).read
              @call_output = @pdftk.dump_data_fields(@input, :output => @output)
            end
          end
        end

        describe "#fill_form" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.fill_form.pdf')).read }
            before(:each) { @call_output = @pdftk.fill_form(@input, path_to_pdf('fields.fdf.spec'), :output => @output) }
          end
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.fill_form.pdf')).read }
            before(:each) { @call_output = @pdftk.fill_form(@input, path_to_pdf('fields.xfdf.spec'), :output => @output) }
          end
        end

        describe "#generate_fdf" do
          it_behaves_like "a working command" do
            before(:all) do
              @example_expect = File.new(path_to_pdf('fields.fdf')).read
              @call_output = @pdftk.generate_fdf(@input,:output => @output)
            end
          end
        end

        describe "#dump_data" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.data')).read }
            before(:each) { @call_output = @pdftk.dump_data(@input,:output => @output) }
          end
        end

        describe "#update_info" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.update_info.pdf')).read }
            before(:each) { @call_output = @pdftk.update_info(@input, path_to_pdf('fields.data.spec'), :output => @output) }
          end
        end

        describe "#attach_files" do
          before(:all) { @attachment_size = File.size(path_to_pdf('attached_file.txt')) }
          before(:each) { @call_output = @pdftk.attach_files(@input, [path_to_pdf('attached_file.txt')], :output => @output) }
          it "should bind the file ine the pdf" do
            if @call_output.is_a?(String)
              output_size = File.size(@call_output)
            else
              @call_output.rewind
              t = Tempfile.new('attachment_output')
              t.write(@call_output.read)
              output_size = File.size(t.path)
              t.close
            end
            if @input.is_a?(String)
              input_size = File.size(@input)
            elsif @input.is_a?(Hash)
              input_size = 0
              @input.each do |file_path, name|
                input_size += File.size(file_path)
              end
            else
              @input.rewind
              t = Tempfile.new('attachment_input')
              t.write(@input.read)
              input_size = File.size(t.path)
              t.close
            end
            total_size = input_size + @attachment_size
            output_size.should >= total_size
          end
          it "should output the correct type" do
            @call_output.should be_kind_of(map_output_type(output_type))
          end
        end

        describe "#unpack_files to path", :if => output_type == :path do
          before(:each) do
            @input = get_input(input_type, 'fields.unpack_files.pdf')
            @input.rewind rescue nil # rewind if possible.
            @output = path_to_pdf('')
            @call_output = @pdftk.unpack_files(@input, @output)
          end
          it "should unpack the files" do
            @call_output.should == @output
            File.unlink(path_to_pdf('unpacked_file.txt')).should == 1
          end
        end

        describe "#unpack_files to tmp dir", :if => output_type == :nil do
          before(:each) do
            @input = get_input(input_type, 'fields.unpack_files.pdf')
            @input.rewind rescue nil # rewind if possible.
            @call_output = @pdftk.unpack_files(@input, @output)
          end
          it "should unpack the files" do
            @call_output.should == Dir.tmpdir
            File.unlink(File.join(Dir.tmpdir, 'unpacked_file.txt')).should == 1
          end
        end

        describe "#background" do
          it_behaves_like "a working command"do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.background.pdf')).read }
            before(:each) { @call_output = @pdftk.background(@input, path_to_pdf('a.pdf'), :output => @output) }
          end

          pending "spec multibackground also"
        end

        describe "#stamp" do
          it_behaves_like "a working command"do
            before(:all) { @example_expect = File.new(path_to_pdf('fields.stamp.pdf')).read }
            before(:each) { @call_output = @pdftk.stamp(@input, path_to_pdf('a.pdf'), :output => @output) }
          end

          pending "check if the output is really a stamp & spec multistamp also"
        end

        describe "#cat" do
          pending "implementation"
        end

        describe "#shuffle" do
          pending "implementation"
        end

        describe "#burst", :if => output_type == :path do
          pending "implementation"
        end
      end

      #context "burst" do
      #  it "should call #pdtk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('fields.pdf'), :operation => :burst})
      #    @pdftk.burst(path_to_pdf('fields.pdf'))
      #    @pdftk = ActivePdftk::Wrapper.new
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => path_to_pdf('fields.pdf'), :operation => :burst, :options => {:encrypt  => :'40bit'}})
      #    @pdftk.burst(path_to_pdf('fields.pdf'), :options => {:encrypt  => :'40bit'})
      #  end
      #
      #  it "should put a file in the system tmpdir when no output location given" do
      #    @pdftk.burst(path_to_pdf('fields.pdf'))
      #    File.unlink(File.join(Dir.tmpdir, 'pg_0001.pdf')).should == 1
      #  end
      #
      #  it "should put a file in the system tmpdir when no output location given but a page name format given" do
      #    @pdftk.burst(path_to_pdf('fields.pdf'), :output => 'page_%02d.pdf')
      #    File.unlink(File.join(Dir.tmpdir, 'page_01.pdf')).should == 1
      #  end
      #
      #  it "should put a file in the specified path" do
      #    @pdftk.burst(path_to_pdf('fields.pdf'), :output => path_to_pdf('page_%02d.pdf').to_s)
      #    File.unlink(path_to_pdf('page_01.pdf')).should == 1
      #  end
      #end
      #
      #context "cat" do
      #  it "should call #pdftk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => {'a.pdf' => 'foo', 'b.pdf' => nil}, :operation => {:cat => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]}})
      #    @pdftk.cat([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}])
      #  end
      #
      #  it "should output the generated pdf" do
      #    @pdftk.cat([{:pdf => path_to_pdf('a.pdf'), :pass => 'foo'}, {:pdf => path_to_pdf('b.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => path_to_pdf('cat.pdf'))
      #    File.unlink(path_to_pdf('cat.pdf')).should == 1
      #  end
      #end
      #
      #context "shuffle" do
      #  it "should call #pdftk on @call" do
      #    ActivePdftk::Call.any_instance.should_receive(:pdftk).with({:input => {'a.pdf' => 'foo', 'b.pdf' => nil}, :operation => {:shuffle => [{:pdf => 'a.pdf'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}]}})
      #    @pdftk.shuffle([{:pdf => 'a.pdf', :pass => 'foo'}, {:pdf => 'b.pdf', :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}])
      #  end
      #
      #  it "should output the generated pdf" do
      #    @pdftk.shuffle([{:pdf => path_to_pdf('a.pdf'), :pass => 'foo'}, {:pdf => path_to_pdf('b.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => path_to_pdf('shuffle.pdf'))
      #    File.unlink(path_to_pdf('shuffle.pdf')).should == 1
      #  end
      #end
      #
      #context "unpack_files" do
      #  it "should return Dir.tmpdir" do
      #    @pdftk.attach_files(path_to_pdf('fields.pdf'), [path_to_pdf('attached_file.txt')], :output => path_to_pdf('attached.pdf'))
      #    @pdftk.unpack_files(path_to_pdf('attached.pdf')).should == Dir.tmpdir
      #    File.unlink(path_to_pdf('attached.pdf')).should == 1
      #  end
      #
      #  it "should return the specified output directory" do
      #    @pdftk.attach_files(path_to_pdf('fields.pdf'), [path_to_pdf('attached_file.txt')], :output => path_to_pdf('attached.pdf'))
      #    @pdftk.unpack_files(path_to_pdf('attached.pdf'), path_to_pdf(nil)).should == path_to_pdf(nil)
      #    File.unlink(path_to_pdf('attached.pdf')).should == 1
      #  end
      #end

    end # each outputs
  end # each inputs
end # Wrapper
