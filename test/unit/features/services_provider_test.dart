import 'package:discovaa/features/services/data/models/service_api_models.dart';
import 'package:discovaa/features/services/data/models/service_model.dart';
import 'package:discovaa/features/services/presentation/providers/services_provider.dart';
import 'package:discovaa/features/profile/data/models/profile_api_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  // Helper to add a test service through the notifier
  void addTestService({
    String title = 'Test Service',
    String category = 'Test',
    PricingModel pricingModel = PricingModel.fixed,
    PriceType priceType = PriceType.fixed,
    double? amount = 5000,
  }) {
    container
        .read(servicesProvider.notifier)
        .addService(
          title: title,
          category: category,
          description: 'Test description',
          pricingModel: pricingModel,
          priceType: priceType,
          currency: 'NGN',
          amount: amount,
          isActive: true,
        );
  }

  group('ServicesNotifier', () {
    test('initial state has empty services list', () {
      final state = container.read(servicesProvider);
      expect(state.services, isEmpty);
      expect(state.status, ServicesStatus.idle);
      expect(state.searchQuery, '');
    });

    test('addService adds a service and sets status to success', () {
      addTestService(title: 'Plumbing Repair');
      final state = container.read(servicesProvider);
      expect(state.services.length, 1);
      expect(state.services.first.title, 'Plumbing Repair');
      expect(state.status, ServicesStatus.success);
    });

    test('addService trims whitespace from title and category', () {
      container
          .read(servicesProvider.notifier)
          .addService(
            title: '  Haircut  ',
            category: '  Beauty  ',
            description: '',
            pricingModel: PricingModel.hourly,
            priceType: PriceType.fixed,
            currency: 'NGN',
          );
      final svc = container.read(servicesProvider).services.first;
      expect(svc.title, 'Haircut');
      expect(svc.category, 'Beauty');
    });

    test('deleteService removes the correct service', () {
      addTestService(title: 'Service A');
      addTestService(title: 'Service B');
      final state = container.read(servicesProvider);
      expect(state.services.length, 2);

      final idToDelete = state.services.first.id;
      container.read(servicesProvider.notifier).deleteService(idToDelete);
      final updated = container.read(servicesProvider);
      expect(updated.services.length, 1);
      expect(updated.services.first.title, 'Service B');
    });

    test('toggleServiceStatus flips isActive correctly', () {
      addTestService();
      final service = container.read(servicesProvider).services.first;
      expect(service.isActive, isTrue);

      container.read(servicesProvider.notifier).toggleServiceStatus(service);
      expect(container.read(servicesProvider).services.first.isActive, isFalse);

      final updatedService = container.read(servicesProvider).services.first;
      container.read(servicesProvider.notifier).toggleServiceStatus(updatedService);
      expect(container.read(servicesProvider).services.first.isActive, isTrue);
    });

    test('updateService replaces the service in list', () {
      addTestService(title: 'Old Title');
      final original = container.read(servicesProvider).services.first;
      final updated = original.copyWith(title: 'New Title', amount: 9999);
      container.read(servicesProvider.notifier).updateService(updated);

      final result = container.read(servicesProvider).services.first;
      expect(result.title, 'New Title');
      expect(result.amount, 9999);
    });

    test('updateSearch filters services correctly', () {
      addTestService(title: 'Carpentry');
      addTestService(title: 'Plumbing');

      container.read(servicesProvider.notifier).updateSearch('plumb');
      final filtered = container.read(filteredServicesProvider);
      expect(filtered.length, 1);
      expect(filtered.first.title, 'Plumbing');
    });

    test('updateSearch with empty string returns all services', () {
      addTestService(title: 'Carpentry');
      addTestService(title: 'Plumbing');
      container.read(servicesProvider.notifier).updateSearch('');
      expect(container.read(filteredServicesProvider).length, 2);
    });

    test('serviceCountProvider returns correct count', () {
      expect(container.read(serviceCountProvider), 0);
      addTestService();
      expect(container.read(serviceCountProvider), 1);
      addTestService();
      expect(container.read(serviceCountProvider), 2);
    });
  });

  group('ServiceModel', () {
    test('formattedPrice returns correct string for fixed pricing', () {
      final svc = ServiceModel(
        id: '1',
        title: 'Test',
        category: '',
        description: '',
        pricingModel: PricingModel.fixed,
        priceType: PriceType.fixed,
        currency: 'NGN',
        amount: 5000,
        createdAt: DateTime.now(),
      );
      expect(svc.formattedPrice, 'NGN 5000');
    });

    test('formattedPrice appends /hr for hourly pricing', () {
      final svc = ServiceModel(
        id: '1',
        title: 'Test',
        category: '',
        description: '',
        pricingModel: PricingModel.hourly,
        priceType: PriceType.fixed,
        currency: 'NGN',
        amount: 2000,
        createdAt: DateTime.now(),
      );
      expect(svc.formattedPrice, 'NGN 2000/hr');
    });

    test('formattedPrice returns price on request when amount is null', () {
      final svc = ServiceModel(
        id: '1',
        title: 'Test',
        category: '',
        description: '',
        pricingModel: PricingModel.fixed,
        priceType: PriceType.variable,
        currency: 'NGN',
        amount: null,
        createdAt: DateTime.now(),
      );
      expect(svc.formattedPrice, 'Price on request');
    });

    test('toJson and fromJson round-trips correctly', () {
      final original = ServiceModel(
        id: 'abc',
        title: 'Painting',
        category: 'Home',
        description: 'Wall painting',
        pricingModel: PricingModel.package,
        priceType: PriceType.fixed,
        currency: 'NGN',
        amount: 15000,
        durationMinutes: 120,
        isActive: false,
        createdAt: DateTime(2025, 1, 15),
      );

      final json = original.toJson();
      final restored = ServiceModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.pricingModel, original.pricingModel);
      expect(restored.priceType, original.priceType);
      expect(restored.amount, original.amount);
      expect(restored.durationMinutes, original.durationMinutes);
      expect(restored.isActive, original.isActive);
    });
  });

  group('UserMeDto', () {
    test('extracts providerId from nested provider object payload', () {
      final dto = UserMeDto.fromJson({
        'id': 'user-1',
        'email': 'artisan@example.com',
        'provider': {'id': 'provider-123', 'display_name': 'Artisan Provider'},
      });

      expect(dto.providerId, 'provider-123');
    });

    test('uses provider_id when provider payload is absent', () {
      final dto = UserMeDto.fromJson({
        'id': 'user-1',
        'email': 'artisan@example.com',
        'provider_id': 'provider-456',
      });

      expect(dto.providerId, 'provider-456');
    });
  });

  group('AddServiceFormNotifier', () {
    test('initial form state has correct defaults', () {
      final form = container.read(addServiceFormProvider);
      expect(form.title, '');
      expect(form.currency, 'NGN');
      expect(form.pricingModel, PricingModel.fixed);
      expect(form.priceType, PriceType.fixed);
      expect(form.isActive, isTrue);
      expect(form.submitted, isFalse);
    });

    test('updateTitle updates the title field', () {
      container.read(addServiceFormProvider.notifier).updateTitle('Haircut');
      expect(container.read(addServiceFormProvider).title, 'Haircut');
    });

    test('isFormValid is false when title is empty', () {
      container
          .read(addServiceFormProvider.notifier)
          .updateCategory(name: 'Beauty', id: 'beauty');
      expect(container.read(addServiceFormProvider).isFormValid, isFalse);
    });

    test('isFormValid is true when title and category are filled', () {
      container.read(addServiceFormProvider.notifier).updateTitle('Haircut');
      container
          .read(addServiceFormProvider.notifier)
          .updateCategory(name: 'Beauty', id: 'beauty');
      expect(container.read(addServiceFormProvider).isFormValid, isTrue);
    });

    test('isAmountValid is false for non-numeric input', () {
      container.read(addServiceFormProvider.notifier).updateAmount('abc');
      expect(container.read(addServiceFormProvider).isAmountValid, isFalse);
    });

    test('reset clears form state to defaults', () {
      container.read(addServiceFormProvider.notifier).updateTitle('Haircut');
      container.read(addServiceFormProvider.notifier).reset();
      expect(container.read(addServiceFormProvider).title, '');
    });

    test('addPendingMedia adds a pending media path', () {
      container
          .read(addServiceFormProvider.notifier)
          .addPendingMedia('/tmp/image-a.jpg');
      final form = container.read(addServiceFormProvider);
      expect(form.pendingMediaPaths, ['/tmp/image-a.jpg']);
      expect(form.totalMediaCount, 1);
    });

    test('removePendingMedia removes a pending media path', () {
      final notifier = container.read(addServiceFormProvider.notifier);
      notifier.addPendingMedia('/tmp/image-a.jpg');
      notifier.addPendingMedia('/tmp/image-b.jpg');
      notifier.removePendingMedia(0);
      final form = container.read(addServiceFormProvider);
      expect(form.pendingMediaPaths, ['/tmp/image-b.jpg']);
    });

    test('setExistingMedia stores existing media urls', () {
      container.read(addServiceFormProvider.notifier).setExistingMedia([
        ServiceMediaDto(
          id: 'media-1',
          serviceId: 'service-1',
          url: 'https://example.com/image.jpg',
          fileType: 'image',
          uploadedAt: DateTime(2026, 1, 1),
        ),
      ]);
      final form = container.read(addServiceFormProvider);
      expect(form.existingMedia.length, 1);
      expect(form.existingMedia.first.url, 'https://example.com/image.jpg');
      expect(form.totalMediaCount, 1);
    });

    test('initial weeklySchedule is empty', () {
      expect(container.read(addServiceFormProvider).weeklySchedule, isEmpty);
    });

    test('toggleDay adds a day with empty slot list', () {
      container.read(addServiceFormProvider.notifier).toggleDay(WeekDay.monday);
      final schedule = container.read(addServiceFormProvider).weeklySchedule;
      expect(schedule.containsKey(WeekDay.monday), isTrue);
      expect(schedule[WeekDay.monday], isEmpty);
    });

    test('toggleDay removes a day when already selected', () {
      final notifier = container.read(addServiceFormProvider.notifier);
      notifier.toggleDay(WeekDay.friday);
      notifier.toggleDay(WeekDay.friday); // toggle off
      expect(
        container
            .read(addServiceFormProvider)
            .weeklySchedule
            .containsKey(WeekDay.friday),
        isFalse,
      );
    });

    test('addSlot adds a slot to the given day', () {
      final notifier = container.read(addServiceFormProvider.notifier);
      notifier.toggleDay(WeekDay.wednesday);
      const slot = ServiceTimeSlot(
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 11, minute: 0),
      );
      notifier.addSlot(WeekDay.wednesday, slot);
      final slots = container
          .read(addServiceFormProvider)
          .weeklySchedule[WeekDay.wednesday];
      expect(slots, isNotNull);
      expect(slots!.length, 1);
      expect(slots.first.start.hour, 9);
      expect(slots.first.end.hour, 11);
    });

    test('removeSlot removes a slot at the given index', () {
      final notifier = container.read(addServiceFormProvider.notifier);
      notifier.toggleDay(WeekDay.tuesday);
      const slotA = ServiceTimeSlot(
        start: TimeOfDay(hour: 8, minute: 0),
        end: TimeOfDay(hour: 10, minute: 0),
      );
      const slotB = ServiceTimeSlot(
        start: TimeOfDay(hour: 13, minute: 0),
        end: TimeOfDay(hour: 15, minute: 0),
      );
      notifier.addSlot(WeekDay.tuesday, slotA);
      notifier.addSlot(WeekDay.tuesday, slotB);
      notifier.removeSlot(WeekDay.tuesday, 0);
      final slots = container
          .read(addServiceFormProvider)
          .weeklySchedule[WeekDay.tuesday]!;
      expect(slots.length, 1);
      expect(slots.first.start.hour, 13);
    });

    test('loadSchedule populates weeklySchedule from existing service', () {
      final notifier = container.read(addServiceFormProvider.notifier);
      final existing = {
        WeekDay.monday: [
          const ServiceTimeSlot(
            start: TimeOfDay(hour: 10, minute: 0),
            end: TimeOfDay(hour: 12, minute: 0),
          ),
        ],
        WeekDay.thursday: <ServiceTimeSlot>[],
      };
      notifier.loadSchedule(existing);
      final form = container.read(addServiceFormProvider);
      expect(form.weeklySchedule.containsKey(WeekDay.monday), isTrue);
      expect(form.weeklySchedule[WeekDay.monday]!.length, 1);
      expect(form.weeklySchedule.containsKey(WeekDay.thursday), isTrue);
    });
  });

  group('ServiceTimeSlot', () {
    test('isValid returns true when start is before end', () {
      const slot = ServiceTimeSlot(
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 17, minute: 0),
      );
      expect(slot.isValid, isTrue);
    });

    test('isValid returns false when start equals end', () {
      const slot = ServiceTimeSlot(
        start: TimeOfDay(hour: 10, minute: 0),
        end: TimeOfDay(hour: 10, minute: 0),
      );
      expect(slot.isValid, isFalse);
    });

    test('isValid returns false when start is after end', () {
      const slot = ServiceTimeSlot(
        start: TimeOfDay(hour: 18, minute: 0),
        end: TimeOfDay(hour: 9, minute: 0),
      );
      expect(slot.isValid, isFalse);
    });

    test('toJson and fromJson round-trips correctly', () {
      const original = ServiceTimeSlot(
        start: TimeOfDay(hour: 8, minute: 30),
        end: TimeOfDay(hour: 16, minute: 45),
      );
      final json = original.toJson();
      final restored = ServiceTimeSlot.fromJson(json);
      expect(restored.start.hour, 8);
      expect(restored.start.minute, 30);
      expect(restored.end.hour, 16);
      expect(restored.end.minute, 45);
    });

    test('ServiceModel toJson/fromJson preserves weeklySchedule', () {
      final model = ServiceModel(
        id: 'sched-1',
        title: 'Cleaning',
        category: 'Home',
        description: 'Deep clean',
        pricingModel: PricingModel.fixed,
        priceType: PriceType.fixed,
        currency: 'NGN',
        amount: 8000,
        weeklySchedule: {
          WeekDay.monday: [
            const ServiceTimeSlot(
              start: TimeOfDay(hour: 8, minute: 0),
              end: TimeOfDay(hour: 12, minute: 0),
            ),
          ],
          WeekDay.friday: [
            const ServiceTimeSlot(
              start: TimeOfDay(hour: 14, minute: 0),
              end: TimeOfDay(hour: 17, minute: 0),
            ),
          ],
        },
        createdAt: DateTime(2025, 6, 1),
      );

      final json = model.toJson();
      final restored = ServiceModel.fromJson(json);

      expect(restored.weeklySchedule.containsKey(WeekDay.monday), isTrue);
      expect(restored.weeklySchedule[WeekDay.monday]!.first.start.hour, 8);
      expect(restored.weeklySchedule.containsKey(WeekDay.friday), isTrue);
      expect(restored.weeklySchedule[WeekDay.friday]!.first.end.hour, 17);
    });
  });
}
