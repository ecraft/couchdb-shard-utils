# frozen_string_literal: true

require 'shard_utils'

# rubocop:disable Metrics/BlockLength

RSpec.describe ShardUtils do
  let(:db) { 'foo' }

  let(:config) do
    '{
      "_id": "_users",
      "_rev": "1-90ee291e872701520077b4494bb66186",
      "shard_suffix": [
          46, 49, 53, 52, 53, 48, 51, 51, 49, 50, 52
      ],
      "changelog": [
          [
              "add",
              "00000000-7fffffff",
              "couchdb@localhost"
          ],
          [
              "add",
              "80000000-ffffffff",
              "couchdb@localhost"
          ]

      ],
      "by_node": {
          "couchdb@localhost": [
              "00000000-7fffffff",
              "80000000-ffffffff"
          ]
      },
      "by_range": {
          "00000000-7fffffff": [
              "couchdb@localhost"
          ],
          "80000000-ffffffff": [
              "couchdb@localhost"
          ]
      }
    }'
  end

  let(:config_with_node) do
    '{
      "_id": "_users",
      "_rev": "1-90ee291e872701520077b4494bb66186",
      "shard_suffix": [
          46, 49, 53, 52, 53, 48, 51, 51, 49, 50, 52
      ],
      "changelog": [
          [
              "add",
              "00000000-7fffffff",
              "couchdb@localhost"
          ],
          [
              "add",
              "80000000-ffffffff",
              "couchdb@localhost"
          ],
          [
            "add",
            "00000000-7fffffff",
            "couchdb@f.q.d.n"
        ],
        [
            "add",
            "80000000-ffffffff",
            "couchdb@f.q.d.n"
        ]
      ],
      "by_node": {
          "couchdb@localhost": [
              "00000000-7fffffff",
              "80000000-ffffffff"
          ],
          "couchdb@f.q.d.n": [
            "00000000-7fffffff",
            "80000000-ffffffff"
          ]
      },
      "by_range": {
          "00000000-7fffffff": [
              "couchdb@localhost",
              "couchdb@f.q.d.n"
          ],
          "80000000-ffffffff": [
              "couchdb@localhost",
              "couchdb@f.q.d.n"
          ]
      }
    }'
  end
  describe '#create_add_node_changes' do
    before do
      allow(subject).to receive(:options).and_return({ template: 'couchdb@localhost' })
      allow(subject).to receive(:node_name).and_return('couchdb@f.q.d.n')
    end
    context 'when node is not present' do
      it 'the changes should be calculated correctly' do
        expect(subject.create_add_node_changes('_users', JSON.parse(config))).to eq(JSON.parse(config_with_node))
      end
    end

    context 'when node is already present' do
      it 'should not modify config' do
        expect(subject.create_add_node_changes('_users', JSON.parse(config_with_node))).to eq(nil)
      end
    end
  end

  describe '#create_remove_node_changes' do
    let(:config_with_removed_node) do
      '{
      "_id": "_users",
      "_rev": "1-90ee291e872701520077b4494bb66186",
      "shard_suffix": [
          46, 49, 53, 52, 53, 48, 51, 51, 49, 50, 52
      ],
      "changelog": [
          [
              "add",
              "00000000-7fffffff",
              "couchdb@localhost"
          ],
          [
              "add",
              "80000000-ffffffff",
              "couchdb@localhost"
          ],
          [
            "add",
            "00000000-7fffffff",
            "couchdb@f.q.d.n"
          ],
          [
            "add",
            "80000000-ffffffff",
            "couchdb@f.q.d.n"
          ],
          [
            "remove",
            "00000000-7fffffff",
            "couchdb@localhost"
          ],
          [
            "remove",
            "80000000-ffffffff",
            "couchdb@localhost"
          ]
      ],
      "by_node": {
          "couchdb@f.q.d.n": [
            "00000000-7fffffff",
            "80000000-ffffffff"
          ]
      },
      "by_range": {
          "00000000-7fffffff": [
              "couchdb@f.q.d.n"
          ],
          "80000000-ffffffff": [
              "couchdb@f.q.d.n"
          ]
      }
    }'
    end

    context 'when node is not present' do
      it 'should not modify config' do
        expect(subject.create_remove_node_changes('_users', JSON.parse(config))).to eq(nil)
      end
    end

    context 'when node is present' do
      before do
        allow(subject).to receive(:node_name).and_return('couchdb@localhost')
      end
      it 'the changes should be calculated correctly' do
        expect(
          subject.create_remove_node_changes('_users', JSON.parse(config_with_node))
        ).to eq(JSON.parse(config_with_removed_node))
      end
    end
  end
end

# rubocop:enable Metrics/BlockLength
