require_relative '../support/geo'
# TODO: Jim, use constants instead of instantiating factories again? 
FactoryGirl.define do

  minLat = -85
  maxLat = 85
  minLng = -180
  maxLng = 180
  rng    = Random.new(Time.now.to_i)

  # FactoryGirl.build(:geographic_item, :random_point)
  trait :random_point do
    point { RSPEC_GEO_FACTORY.point(minLat + rng.rand * (maxLat - minLat), minLng + rng.rand * (maxLng - minLng)) }
  end

  factory :geographic_item, traits: [:creator_and_updater] do
    factory :valid_geographic_item, aliases: [:geographic_item_with_point_a] do
      point { RSPEC_GEO_FACTORY.point(-88.241413, 40.091655) }
    end

    factory :random_point_geographic_item do
      random_point
    end

    factory :geographic_item_with_point_m do
      point { RSPEC_GEO_FACTORY.point(-88.196736, 40.090091) }
    end

    factory :geographic_item_with_point_u do
      point { RSPEC_GEO_FACTORY.point(-88.204517, 40.110037) }
    end

    factory :geographic_item_with_point_c do
      point { RSPEC_GEO_FACTORY.point(-88.243386, 40.116402) }
    end

    factory :geographic_item_with_line_string do
      line_string { RSPEC_GEO_FACTORY.line_string([RSPEC_GEO_FACTORY.point(-32, 21),
                                                   RSPEC_GEO_FACTORY.point(-25, 21),
                                                   RSPEC_GEO_FACTORY.point(-25, 16),
                                                   RSPEC_GEO_FACTORY.point(-21, 20)]) }
    end

    factory :geographic_item_with_polygon do
      shape = RSPEC_GEO_FACTORY.line_string([RSPEC_GEO_FACTORY.point(-32, 21),
                                             RSPEC_GEO_FACTORY.point(-25, 21),
                                             RSPEC_GEO_FACTORY.point(-25, 16),
                                             RSPEC_GEO_FACTORY.point(-21, 20)])
      polygon { RSPEC_GEO_FACTORY.polygon(shape) }
    end

=begin
'00a0000006000010e60000000500800000030000000100000005c06505229468f1f4c02d0ab728c30f000000000000000000c065052b94690bb8c02d10d728bdb0a80000000000000000c0650589e9be1f33c02d0c21d36d02500000000000000000c065053b94690bb9c02d0a21d36d02580000000000000000c06505229468f1f4c02d0ab728c30f00000000000000000000800000030000000100000016c06553d79468a4a4c02c825728c1fc000000000000000000c06552e99468d82cc02c879728bfd6480000000000000000c06552709468be68c02c814c7e191b980000000000000000c0655226e9be169ac02c8461d36adc800000000000000000c0655230e9be056cc02c8ab728c30ee80000000000000000c06552b194691ce7c02c8e3728bec3700000000000000000c065548de9bdfcd5c02c8fb728c30ef80000000000000000c0655518e9be4a24c02c920c7e12aa600000000000000000c06555dfe9be3061c02c9b0c7e12aa400000000000000000c0655718e9be4a25c02cb4f728c0e9280000000000000000c06557f4e9be6c80c02cbfd728bdb0800000000000000000c065582ce9be27c9c02cbbf728c0e9380000000000000000c065597c9468e0c5c02cae0c7e12aa480000000000000000c0655a549469257dc02ca74c7e191ba80000000000000000c0655a999468d82cc02ca38c7e16f5e00000000000000000c065593c9468e0c5c02c96cc7e14d0100000000000000000c06558b8e9be4a23c02c953728bec3800000000000000000c065579c9468e0c4c02c958c7e16f5c00000000000000000c06557169468cf95c02c941728c421e80000000000000000c0655659e9be1f32c02c8561d36adc980000000000000000c065552a9468ad39c02c813728bec3600000000000000000c06553d79468a4a4c02c825728c1fc00000000000000000000800000030000000100000014c0652e159468fa8ac02c7d9728bfd6580000000000000000c0652e4ee9be5b52c02c82e1d36f28280000000000000000c0652eb99468d82cc02c803728bec3780000000000000000c0652efa9468ad3cc02c847728c534b80000000000000000c0652f3ce9be27c8c02c865728c1fbf80000000000000000c0652f84e9be6c82c02c8621d36d02400000000000000000c0652fd5e9be418fc02c83b728c30f080000000000000000c0652ff29468f1f4c02c883728bec3700000000000000000c0653022e9be38f6c02c8a8c7e16f5e00000000000000000c06530669468cf98c02c8b21d36d02580000000000000000c06530bae9be7daec02c8ab728c30ee80000000000000000c06530d0e9be056ec02c849728bfd6680000000000000000c06530efe9be305fc02c7f61d36adc980000000000000000c065311ce9be27c9c02c7b7728c534a80000000000000000c065315d9468b5d0c02c793728bec3680000000000000000c06530e194691ce5c02c73b728c30ee80000000000000000c0653034e9be6c80c02c71cc7e14d0180000000000000000c0652ed7e9be7518c02c724c7e191b900000000000000000c0652e359468fa8ac02c761728c421d00000000000000000c0652e159468fa8ac02c7d9728bfd658000000000000000000800000030000000100000009c0653456e9be169ac02c5aa1d368b6e00000000000000000c065351fe9be3060c02c60d728bdb0900000000000000000c065356e9469144ec02c603728bec3680000000000000000c06535a39468c6fec02c598c7e16f5c80000000000000000c06535a33f137ffac02c598c7e16f5c80000000000000000c065356194691ce7c02c569728bfd6600000000000000000c065350fe9be3061c02c567728c534b00000000000000000c06534b59468fa89c02c5821d36d02400000000000000000c0653456e9be169ac02c5aa1d368b6e0000000000000000000800000030000000100000006c0656259e9be1f32c0261fcc7e14cff80000000000000000c065629be9be52bac02621d728bdb0780000000000000000c06562c4e9be6c80c0261ee1d36f28180000000000000000c06562bd9468b5d1c0261a4c7e191b780000000000000000c06562549469257cc0261ae1d36f28200000000000000000c0656259e9be1f32c0261fcc7e14cff80000000000000000'
=end

    factory :geographic_item_with_multi_polygon do
      multi_polygon { RSPEC_GEO_FACTORY.multi_polygon(
        [RSPEC_GEO_FACTORY.polygon(
           RSPEC_GEO_FACTORY.line_string(
             [RSPEC_GEO_FACTORY.point(-168.16047115799995, -14.520928643999923),
              RSPEC_GEO_FACTORY.point(-168.16156979099992, -14.532891533999944),
              RSPEC_GEO_FACTORY.point(-168.17308508999994, -14.523695570999877),
              RSPEC_GEO_FACTORY.point(-168.16352291599995, -14.519789320999891),
              RSPEC_GEO_FACTORY.point(-168.16047115799995, -14.520928643999923)])),

         RSPEC_GEO_FACTORY.polygon(
           RSPEC_GEO_FACTORY.line_string(
             [RSPEC_GEO_FACTORY.point(-170.62006588399993, -14.254571221999868),
              RSPEC_GEO_FACTORY.point(-170.59101314999987, -14.264825127999885),
              RSPEC_GEO_FACTORY.point(-170.5762426419999, -14.252536716999927),
              RSPEC_GEO_FACTORY.point(-170.5672501289999, -14.258558851999851),
              RSPEC_GEO_FACTORY.point(-170.5684708319999, -14.27092864399988),
              RSPEC_GEO_FACTORY.point(-170.58417721299995, -14.2777645809999),
              RSPEC_GEO_FACTORY.point(-170.6423233709999, -14.280694268999909),
              RSPEC_GEO_FACTORY.point(-170.65929114499988, -14.28525155999995),
              RSPEC_GEO_FACTORY.point(-170.68358313699994, -14.302829684999892),
              RSPEC_GEO_FACTORY.point(-170.7217911449999, -14.353448174999883),
              RSPEC_GEO_FACTORY.point(-170.74864661399988, -14.374688408999873),
              RSPEC_GEO_FACTORY.point(-170.75548255099991, -14.367120049999912),
              RSPEC_GEO_FACTORY.point(-170.79645748599992, -14.339939059999907),
              RSPEC_GEO_FACTORY.point(-170.82282467399992, -14.326755466999956),
              RSPEC_GEO_FACTORY.point(-170.83124752499987, -14.319431247999944),
              RSPEC_GEO_FACTORY.point(-170.78864498599992, -14.294528903999918),
              RSPEC_GEO_FACTORY.point(-170.77257239499986, -14.291436455999929),
              RSPEC_GEO_FACTORY.point(-170.7378637359999, -14.292087497999887),
              RSPEC_GEO_FACTORY.point(-170.72150631399987, -14.289239190999936),
              RSPEC_GEO_FACTORY.point(-170.69847571499992, -14.260511976999894),
              RSPEC_GEO_FACTORY.point(-170.66144771999987, -14.252373955999872),
              RSPEC_GEO_FACTORY.point(-170.62006588399993, -14.254571221999868)])),

         RSPEC_GEO_FACTORY.polygon(
           RSPEC_GEO_FACTORY.line_string(
             [RSPEC_GEO_FACTORY.point(-169.44013424399992, -14.245293877999913),
              RSPEC_GEO_FACTORY.point(-169.44713294199988, -14.255629164999917),
              RSPEC_GEO_FACTORY.point(-169.46015377499987, -14.250420830999914),
              RSPEC_GEO_FACTORY.point(-169.46808834499996, -14.258721612999906),
              RSPEC_GEO_FACTORY.point(-169.4761856759999, -14.262383721999853),
              RSPEC_GEO_FACTORY.point(-169.48497473899994, -14.261976820999848),
              RSPEC_GEO_FACTORY.point(-169.49486243399994, -14.257256768999937),
              RSPEC_GEO_FACTORY.point(-169.49836178299995, -14.2660458309999),
              RSPEC_GEO_FACTORY.point(-169.50426184799989, -14.270603122999944),
              RSPEC_GEO_FACTORY.point(-169.51252193899995, -14.271742445999891),
              RSPEC_GEO_FACTORY.point(-169.52281653599988, -14.27092864399988),
              RSPEC_GEO_FACTORY.point(-169.52550208199995, -14.258965752999941),
              RSPEC_GEO_FACTORY.point(-169.52928626199989, -14.248793226999894),
              RSPEC_GEO_FACTORY.point(-169.53477942599991, -14.241143487999878),
              RSPEC_GEO_FACTORY.point(-169.54267330599987, -14.236748955999886),
              RSPEC_GEO_FACTORY.point(-169.5275365879999, -14.22600676899988),
              RSPEC_GEO_FACTORY.point(-169.50645911399988, -14.222263278999932),
              RSPEC_GEO_FACTORY.point(-169.4638565749999, -14.223239841999913),
              RSPEC_GEO_FACTORY.point(-169.44404049399992, -14.230645440999893),
              RSPEC_GEO_FACTORY.point(-169.44013424399992, -14.245293877999913)])),

         RSPEC_GEO_FACTORY.polygon(
           RSPEC_GEO_FACTORY.line_string(
             [RSPEC_GEO_FACTORY.point(-169.6356095039999, -14.17701588299991),
              RSPEC_GEO_FACTORY.point(-169.6601456369999, -14.189141533999901),
              RSPEC_GEO_FACTORY.point(-169.6697485019999, -14.187920830999886),
              RSPEC_GEO_FACTORY.point(-169.67621822799987, -14.174899997999901),
              RSPEC_GEO_FACTORY.point(-169.67617753799988, -14.174899997999901),
              RSPEC_GEO_FACTORY.point(-169.66816158799995, -14.169122002999927),
              RSPEC_GEO_FACTORY.point(-169.65819251199994, -14.168877862999892),
              RSPEC_GEO_FACTORY.point(-169.6471654939999, -14.172133070999848),
              RSPEC_GEO_FACTORY.point(-169.6356095039999, -14.17701588299991)])),

         RSPEC_GEO_FACTORY.polygon(
           RSPEC_GEO_FACTORY.line_string(
             [RSPEC_GEO_FACTORY.point(-171.07347571499992, -11.062107028999876),
              RSPEC_GEO_FACTORY.point(-171.08153235599985, -11.066094658999859),
              RSPEC_GEO_FACTORY.point(-171.08653723899988, -11.060316664999888),
              RSPEC_GEO_FACTORY.point(-171.0856420559999, -11.05136484199987),
              RSPEC_GEO_FACTORY.point(-171.0728246739999, -11.052504164999903),
              RSPEC_GEO_FACTORY.point(-171.07347571499992, -11.062107028999876)]))])
      }
    end
  end
end
