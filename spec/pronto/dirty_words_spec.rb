require 'spec_helper'

module Pronto
  describe DirtyWords do
    let(:dirty_words) { DirtyWords.new(patches) }
    let(:patches) { [] }

    describe '#run' do
      around(:example) do |example|
        create_repository
        Dir.chdir(repository_dir) do
          example.run
        end
        delete_repository
      end

      let(:patches) { Pronto::Git::Repository.new(repository_dir).diff('master') }

      context 'patches are nil' do
        let(:patches) { nil }

        it 'returns an empty array' do
          expect(dirty_words.run).to eql([])
        end
      end

      context 'no patches' do
        let(:patches) { [] }

        it 'returns an empty array' do
          expect(dirty_words.run).to eql([])
        end
      end

      context 'with patch data' do
        before(:each) do
          content = <<-HEREDOC
          Line 1 text
          Line 2 text
          Line 3 text
          HEREDOC

          add_to_index('test.txt', content)

          create_commit
        end

        context 'with warnings' do
          before(:each) do
            create_branch('staging', checkout: true)

            updated_content = <<-HEREDOC
            Line 1 text
            Line 2 text ... shit
            Line 3 text
            HEREDOC

            add_to_index('test.txt', updated_content)

            create_commit
          end

          it 'returns correct number of warnings' do
            expect(dirty_words.run.count).to eql(1)
          end

          it 'has correct first message' do
            expect(dirty_words.run.first.msg).to eql('Avoid using one of the seven dirty words')
          end
        end

        context 'no file matches' do
          before(:each) do
            create_branch('staging', checkout: true)

            add_to_index('random.js', 'alert("Hello World!")');

            create_commit
          end

          it 'returns no warnings' do
            expect(dirty_words.run.count).to eql(0)
          end
        end
      end
    end
  end
end
