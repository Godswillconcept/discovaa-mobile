import 'package:discovaa/features/services/data/models/service_api_models.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';

abstract class ServicesRepository {
  Future<List<ServiceModel>> listServices();
  Future<List<String>> listCategoryNames();
  Future<ServiceModel> createService(ServiceModel service);
  Future<ServiceModel> updateService(ServiceModel service);
  Future<void> deleteService(String id);
  Future<List<ServiceMediaDto>> listServiceMedia();
  Future<ServiceMediaDto> uploadServiceMedia({
    required String serviceId,
    required String filePath,
    String fileType,
    String? description,
  });
  Future<void> deleteServiceMedia(String id);
  Future<List<ServiceModel>> fetchFeaturedServices({int? limit});
}
