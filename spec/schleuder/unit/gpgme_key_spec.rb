require "spec_helper"

describe GPGME::Key do
  describe '#minimal' do
    it 'returns a minimal key' do
      list = create(:list)
      list.import_key(File.read('spec/fixtures/schleuder_at_example_public_key.txt'))
      
      expect(list.key.minimal()).to eq(File.read('spec/fixtures/schleuder_at_example_public_key_minimal.gpg', mode: 'rb'))
    end
  end

  describe "#summary" do
    it "displays the expected basic attributes" do
      list = create(:list)

      key = list.key

      expect(key.summary).to match(/0x59C71FB38AEE22E091C78259D06350440F759BD3 schleuder@example.org \d{4}-\d{2}-\d{2}/)
    end

    it "displays the expected attributes for an expiring key" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/expiring_key.txt"))

      key = list.key("421FBF7190640136788593CD9EE9BE5929CACC20")

      expect(key.summary).to match(/0x421FBF7190640136788593CD9EE9BE5929CACC20 expiringkey@example.org \d{4}-\d{2}-\d{2} \[expires: \d{4}-\d{2}-\d{2}\]/)
    end

    it "displays the expected attributes for an expired key" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/expired_key.txt"))

      key = list.key("98769E8A1091F36BD88403ECF71A3F8412D83889")

      expect(key.summary).to match(/0x98769E8A1091F36BD88403ECF71A3F8412D83889 bla@foo \d{4}-\d{2}-\d{2} \[expired: \d{4}-\d{2}-\d{2}\]/)
    end

    it "displays the expected attributes for a revoked key" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/revoked_key.txt"))

      key = list.key("7E783CDE6D1EFE6D2409739C098AC83A4C0028E9")

      expect(key.summary).to match(/0x7E783CDE6D1EFE6D2409739C098AC83A4C0028E9 paz@nadir.org \d{4}-\d{2}-\d{2} \[revoked\]/)
    end

    # gpgme.rb doesn't report missing encryption-capability properly yet.
    it "displays the expected attributes for a key that's not capable of encryption" do
      list = create(:list)
      list.import_key(File.read("spec/fixtures/signonly_key.txt"))

      key = list.key("B1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E")

      expect(key.summary).to match(/0xB1CD8BB15C2673C6BFD8FA4B70B2CF29E01AD53E signonly@example.org \d{4}-\d{2}-\d{2} \[not capable of encryption\]/)
    end
  end

  describe '.valid_fingerprint?' do
    context 'valid fingerprints' do
      ['59C71FB38AEE22E091C78259D06350440F759BD3',
       '0x59C71FB38AEE22E091C78259D06350440F759BD3',
       '59C71FB38AEE22E091C78259D0635044',
       '0x59C71FB38AEE22E091C78259D0635044',
      ].each do |fp|
        it "accepts #{fp} as a valid fingerprint" do
          expect(described_class.valid_fingerprint?(fp)).to be_truthy
        end
      end
    end
    context 'invalid fingerprints' do
      ['Z9C71FB38AEE22E091C78259D06350440F759BD3',
       '59C71FB38AEE22E091C78259D06350440F759BD3A',
       '59C71FB38AEE22E091C78259D06350440F759BD',
       '0x59C71FB38AEE22E091C78259D06350440F759B',
       'Z9C71FB38AEE22E091C78259D0635044',
       'Z9C71FB38AEE22E091C78259D0635044',
      ].each do |fp|
        it "rejects #{fp} as an invalid fingerprint" do
          expect(described_class.valid_fingerprint?(fp)).to be_falsey
        end
      end
    end
  end
end
