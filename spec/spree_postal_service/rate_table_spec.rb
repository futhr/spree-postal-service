# frozen_string_literal: true

RSpec.describe SpreePostalService::RateTable do
  subject(:table) { described_class.new(thresholds: "1 2 5 10 20", prices: "6 9 12 15 18") }

  it "returns zero for zero chargeable weight" do
    expect(table.quote("0")).to eq(BigDecimal("0"))
  end

  it "prices exact and just-over thresholds deterministically" do
    expect(table.quote("1")).to eq(BigDecimal("6"))
    expect(table.quote("1.0001")).to eq(BigDecimal("9"))
    expect(table.quote("20")).to eq(BigDecimal("18"))
    expect(table.quote("20.0001")).to eq(BigDecimal("24"))
  end

  it "preserves legacy repeated maximum-band pricing" do
    expect(table.quote("25")).to eq(BigDecimal("30"))
    expect(table.quote("40")).to eq(BigDecimal("36"))
    expect(table.quote("41")).to eq(BigDecimal("42"))
  end

  it "rejects malformed tables" do
    expect { described_class.new(thresholds: "1 5 2", prices: "1 2 3") }
      .to raise_error(SpreePostalService::ConfigurationError, /strictly increasing/)

    expect { described_class.new(thresholds: "1 2", prices: "1") }
      .to raise_error(SpreePostalService::ConfigurationError, /same number/)
  end
end
