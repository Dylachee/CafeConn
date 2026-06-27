import '../models/models.dart';
import '../theme/app_colors.dart';

class MockCafeApi {
  List<AppUser> seedUsers() => const [
        AppUser(id: 'admin', name: 'Администратор', role: UserRole.admin, status: 'В системе'),
        AppUser(id: 'manager', name: 'Алекс Ривера', role: UserRole.manager, status: 'Онлайн'),
        AppUser(id: 'waiter', name: 'Елена Соколова', role: UserRole.waiter, status: 'На смене'),
        AppUser(id: 'cook', name: 'Марко Чен', role: UserRole.cook, status: 'На кухне'),
        AppUser(id: 'bar', name: 'Сара Дженкинс', role: UserRole.bartender, status: 'За баром'),
      ];

  List<CafeTable> seedTables() => List.generate(12, (i) {
        final statuses = [
          TableStatus.free,
          TableStatus.occupied,
          TableStatus.awaitingPayment,
          TableStatus.ready,
          TableStatus.late
        ];
        final status = statuses[i % statuses.length];
        return CafeTable(
          id: 't${i + 1}',
          number: (i + 1).toString(),
          seats: (i % 4) + 2,
          status: status,
          guestCount: status == TableStatus.free ? 0 : (i % 4) + 1,
          notes: i % 3 == 0 ? const ['Аллергия на орехи', 'VIP'] : const [],
          colorTag: i % 2 == 0 ? AppColors.bar : AppColors.kitchen,
        );
      });

  List<MenuItem> seedMenu() => const [
        MenuItem(
            id: 'm1',
            name: 'Флэт уайт',
            description: 'Шёлковый эспрессо с мягким молоком.',
            price: 4.50,
            category: 'Кофе',
            imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=400',
            tags: ['Dairy'],
            prepTime: 4,
            promo: true,
            composition: 'Эспрессо, молоко 3.2%, микропена.',
            allergens: ['Dairy'],
            station: FeedType.bar),
        MenuItem(
            id: 'm2',
            name: 'Круассан',
            description: 'Тёплый хрустящий круассан.',
            price: 3.80,
            category: 'Выпечка',
            imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400',
            tags: ['Gluten'],
            prepTime: 3,
            composition: 'Мука, сливочное масло, сахар, дрожжи.',
            allergens: ['Gluten', 'Eggs'],
            station: FeedType.kitchen),
        MenuItem(
            id: 'm3',
            name: 'Бенедикт',
            description: 'Яйца пашот с голландским соусом.',
            price: 18.50,
            category: 'Завтраки',
            imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
            tags: ['Eggs'],
            prepTime: 14,
            promo: true,
            composition: 'Яйца, бриошь, бекон, голландский соус.',
            allergens: ['Eggs', 'Gluten', 'Dairy'],
            station: FeedType.kitchen),
        MenuItem(
            id: 'm4',
            name: 'Авокадо тост',
            description: 'Заквасочный хлеб и авокадо.',
            price: 12.00,
            category: 'Завтраки',
            imageUrl: 'https://images.unsplash.com/photo-1525351484163-7529414344d8?w=400',
            tags: ['Vegan'],
            prepTime: 8,
            composition: 'Заквасочный хлеб, авокадо, семена, чили.',
            allergens: ['Gluten'],
            station: FeedType.kitchen),
        MenuItem(
            id: 'm5',
            name: 'Колд брю',
            description: 'Кофе холодной экстракции.',
            price: 5.20,
            category: 'Кофе',
            imageUrl: 'https://images.unsplash.com/photo-1517701604599-bb29b565090c?w=400',
            tags: ['Vegan'],
            prepTime: 2,
            composition: 'Кофе холодной заварки 12 часов.',
            station: FeedType.bar),
        MenuItem(
            id: 'm6',
            name: 'Лимонад',
            description: 'Домашний лимонад с базиликом.',
            price: 4.90,
            category: 'Напитки',
            imageUrl: 'https://images.unsplash.com/photo-1621263764928-df1444c5e859?w=400',
            tags: ['Vegan'],
            prepTime: 3,
            composition: 'Лимонный сок, сахарный сироп, базилик, газировка.',
            station: FeedType.bar),
      ];

  List<ChatGroup> seedGroups(List<AppUser> staff) => [
        ChatGroup(id: 'g1', name: 'Общий чат', type: null, members: staff.map((s) => s.id).toList(), pinned: true),
        ChatGroup(
            id: 'g2',
            name: 'Кухня',
            type: FeedType.kitchen,
            members: staff
                .where((s) =>
                    s.role == UserRole.cook ||
                    s.role == UserRole.manager ||
                    s.role == UserRole.admin)
                .map((s) => s.id)
                .toList(),
            pinned: true),
        ChatGroup(
            id: 'g3',
            name: 'Бар',
            type: FeedType.bar,
            members: staff
                .where((s) =>
                    s.role == UserRole.bartender ||
                    s.role == UserRole.manager ||
                    s.role == UserRole.admin)
                .map((s) => s.id)
                .toList()),
      ];

  List<ChatMessage> seedMessages(List<ChatGroup> groups) => [
        ChatMessage(
            id: 'm1',
            groupId: groups[0].id,
            senderId: 'waiter',
            text: '#orders Стол 04 сделал заказ, проверяю напитки.',
            tags: const ['#orders'],
            timestamp: DateTime.now().subtract(const Duration(minutes: 22))),
        ChatMessage(
            id: 'm2',
            groupId: groups[1].id,
            senderId: 'cook',
            text: '#kitchen Бенедикт будет готов через минуту.',
            tags: const ['#kitchen'],
            timestamp: DateTime.now().subtract(const Duration(minutes: 11))),
      ];
}
