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
      if example.metadata[:genesis] && @output.is_a?(String)
        FileUtils.copy_entry(@output, @example_expect.to_s, true, false, true)
      else
        @call_output.should have_the_content_of(@example_expect)
      end
    end

    after(:each) { remove_output(@call_output) }
  end

  shared_examples "a combination command" do
    it "should return a #{@output.nil? ? StringIO : @output.class}" do
      @call_output.should be_kind_of(@output.nil? ? StringIO : @output.class)
    end

    it "should return expected data" do
      if example.metadata[:genesis] && @output.is_a?(String)
        FileUtils.copy_entry(@output, @example_expect.to_s, true, false, true)
      else
        @call_output.should look_like_the_same_pdf_as(@example_expect)
      end
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
            before(:all) { @example_expect = fixtures_path('dump_data_fields/expect.data_fields') }
            before(:each) { @call_output = @pdftk.dump_data_fields(@input, :output => @output) }
          end
        end

        describe "#fill_form" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('fill_form/expect.pdf') }
            before(:each) { @call_output = @pdftk.fill_form(@input, path_to_pdf('fill_form/spec.fdf'), :output => @output) }
          end
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('fill_form/expect.pdf') }
            before(:each) { @call_output = @pdftk.fill_form(@input, path_to_pdf('fill_form/spec.xfdf'), :output => @output) }
          end
        end

        describe "#generate_fdf" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('generate_fdf/expect.fdf') }
            before(:each) { @call_output = @pdftk.generate_fdf(@input,:output => @output) }
          end
        end

        describe "#dump_data" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('dump_data/expect.data') }
            before(:each) { @call_output = @pdftk.dump_data(@input,:output => @output) }
          end
        end

        describe "#update_info" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('update_info/expect.pdf') }
            before(:each) { @call_output = @pdftk.update_info(@input, path_to_pdf('update_info/spec.data'), :output => @output) }
          end
        end

        describe "#unpack_files" do
          before(:all) { @example_expect = fixtures_path('unpack_files/expect') }

          context "to path", :if => output_type == :path do
            before(:each) do
              @input = get_input(input_type, 'unpack_files/spec.pdf')
              @input.rewind rescue nil # rewind if possible.

              Dir.mkdir(out_path = fixtures_path('output'))
              @output = Dir.new(out_path)

              @call_output = @pdftk.unpack_files(@input, @output.path)
            end

            after(:each) { FileUtils.remove_entry_secure @output.path }

            it "should unpack the files" do
              @call_output.should == @output.path
              fixtures_path('output').should have_the_content_of(@example_expect)
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

              @example_expect.children(false).each do |file|
                (Pathname.new(Dir.tmpdir) + file).should have_the_content_of(@example_expect + file)
              end
            end
          end
        end

        describe "#attach_files" do
          before(:each) do
            @call_output = @pdftk.attach_files(@input, fixtures_path('attach_files/expect', true).collect(&:to_s), :output => @output)
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
            before(:all) { @example_expect = fixtures_path('background/expect.pdf') }
            before(:each) { @call_output = @pdftk.background(get_input(input_type, 'multi.pdf'), path_to_pdf('poly.pdf'), :output => @output) }
          end
        end

        describe "#multibackground" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('multibackground/expect.pdf') }
            before(:each) { @call_output = @pdftk.multibackground(get_input(input_type, 'multi.pdf'), path_to_pdf('poly.pdf'), :output => @output) }
          end
        end

        describe "#stamp" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('stamp/expect.pdf') }
            before(:each) { @call_output = @pdftk.stamp(get_input(input_type, 'multi.pdf'), path_to_pdf('poly.pdf'), :output => @output) }
          end
        end

        describe "#multistamp" do
          it_behaves_like "a working command" do
            before(:all) { @example_expect = fixtures_path('multistamp/expect.pdf') }
            before(:each) { @call_output = @pdftk.multistamp(get_input(input_type, 'multi.pdf'), path_to_pdf('poly.pdf'), :output => @output) }
          end
        end

        describe "#cat" do
          it_behaves_like "a combination command" do
            before(:all) { @example_expect = fixtures_path('cat/expect.pdf')}
            before(:each) { @call_output = @pdftk.cat([{:pdf => path_to_pdf('multi.pdf')}, {:pdf => path_to_pdf('poly.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => @output) }
          end
        end

        describe "#shuffle" do
          it_behaves_like "a combination command" do
            before(:all) { @example_expect = fixtures_path('shuffle/expect.pdf')}
            before(:each) { @call_output = @pdftk.shuffle([{:pdf => path_to_pdf('multi.pdf')}, {:pdf => path_to_pdf('poly.pdf'), :start => 1, :end => 'end', :orientation => 'N', :pages => 'even'}], :output => @output) }
          end
        end

        describe "#burst" do
          before(:all) { @example_expect = fixtures_path('burst/expect') }

          context 'to path', :if => output_type == :path do
            before(:each) do
              @input = get_input(input_type, 'multi.pdf')
              @input.rewind rescue nil # rewind if possible.

              Dir.mkdir(out_path = fixtures_path('output'))
              @output = Dir.new(out_path)

              @call_output = @pdftk.burst(@input, :output => @output.path + '/pg_%04d.pdf')
            end

            after(:each) { FileUtils.remove_entry_secure @output.path }

            it "should file into single pages" do
              if example.metadata[:genesis]
                FileUtils.copy_entry(@output.path, @example_expect.to_s, true, false, true)
              else
                @call_output.should == @output.path + '/pg_%04d.pdf'
                fixtures_path('output').should look_like_the_same_pdf_as(@example_expect)
              end
            end
          end

          context "#to temporary directory", :if => output_type == :nil do
            before(:each) do
              @input = get_input(input_type, 'multi.pdf')
              @input.rewind rescue nil # rewind if possible.
            end

            it "should file into single pages" do
              @pdftk.burst(@input, :output => nil).should == Dir.tmpdir

              @example_expect.children(false).each do |file|
                (Pathname.new(Dir.tmpdir) + file).should look_like_the_same_pdf_as(@example_expect + file)
                FileUtils.remove_file(Pathname.new(Dir.tmpdir) + file)
              end
            end

            it "should put a file in the system tmpdir when no output location given but a page name format given" do
              @pdftk.burst(@input, :output => 'page_%02d.pdf').should == 'page_%02d.pdf'

              @example_expect.children(false).each do |file|
                index = file.basename.to_s.match(/(\d+)/)[0].to_i
                (Pathname.new(Dir.tmpdir) + ("page_%02d.pdf" % index)).should look_like_the_same_pdf_as(@example_expect + file)
                FileUtils.remove_file(Pathname.new(Dir.tmpdir) + ("page_%02d.pdf" % index))
              end
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
